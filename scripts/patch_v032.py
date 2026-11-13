from pathlib import Path
import shutil

ROOT=Path("build-v03/app/src/main/java/com/claudemobilestudio/app")
def edit(name, edits):
    path=ROOT/name
    source=path.read_text(encoding="utf-8")
    for old,new in edits:
        if old not in source: raise RuntimeError("Cannot patch "+name+": "+old[:90])
        source=source.replace(old,new,1)
    path.write_text(source,encoding="utf-8")

shutil.copyfile("scripts/StreamDecoder_v032.java",ROOT/"StreamDecoder.java")
edit("AgentEngine.java", [
    ('interface Progress { void post(String text); }',
     'interface Progress { void post(String text); default void preview(String text) {} }'),
    ('    private boolean pendingTask=false;',
     '    private boolean pendingTask=false;\n    private boolean connectionChecked=false;'),
    ('        messages.put(new JSONObject().put("role","user").put("content",userBlocks));',
     '        preflight(progress);\n        messages.put(new JSONObject().put("role","user").put("content",userBlocks));'),
    ('        progress.post("Retomando do último ponto salvo, sem repetir a leitura de arquivos já concluída");',
     '        preflight(progress);\n        progress.post("Retomando a tarefa. Uma nova chamada pode consumir tokens.");'),
    ('        for(int round=0;round<12;round++){\n            progress.post("Consultando " + model + " · etapa " + (round+1) + "/12");',
     '        // Maximum two paid calls per user action; more require explicit Resume.\n        for(int round=0;round<2;round++){\n            progress.post("Consultando " + model + " · chamada " + (round+1) + " de 2");'),
    ('        saveHistory();\n        return "Limite de 12 etapas alcançado. Continue a tarefa em uma nova mensagem.\\n"+finalText;',
     '        saveHistory();\n        progress.post("Pausado para evitar chamadas adicionais automáticas.");\n        return (finalText.length()>0?finalText.toString().trim()+"\\n\\n":"") + "⏸ Pausado após até 2 chamadas pagas. Toque em Retomar tarefa somente se autorizar novas chamadas à API.";'),
])
path=ROOT/"AgentEngine.java"
source=path.read_text(encoding="utf-8")
start=source.index("    private JSONObject callApi(Progress progress) throws Exception {")
end=source.index("    private String system(){",start)
source=source[:start]+r"""    /** Verifies credentials and model before paid inference. */
    private void preflight(Progress progress) throws Exception {
        if(connectionChecked)return;
        progress.post("Verificando chave, IP, plano e modelo sem gerar texto pago...");
        Map<String,String> h=new HashMap<>();h.put("x-api-key",key);
        JSONObject catalog=Net.json("GET","https://api.infinitemodel.app/v1/models",h,null,16000);
        JSONArray available=catalog.optJSONArray("data");
        if(available!=null && available.length()>0) {
            boolean found=false;
            for(int i=0;i<available.length();i++) {
                JSONObject entry=available.optJSONObject(i);
                if(entry!=null && model.equals(entry.optString("id")))found=true;
                if(model.equals(available.optString(i)))found=true;
            }
            if(!found)throw new IOException("O modelo "+model+" não está habilitado nesta chave. Escolha um modelo disponível em Configurações.");
        }
        connectionChecked=true;
        progress.post("Chave/IP confirmados. Enviando solicitação à IA.");
    }
    private JSONObject callApi(Progress progress) throws Exception {
        Map<String,String> h=new HashMap<>();h.put("x-api-key",key);h.put("anthropic-version","2023-06-01");
        JSONObject request=new JSONObject().put("model",model).put("max_tokens",2048)
           .put("system",system()).put("messages",messages).put("tools",tools()).put("stream",true);
        progress.post("Recebendo resposta por streaming. Não repetiremos cobranças automaticamente.");
        return Net.streamMessage(gateway,h,request,value->progress.preview(value));
    }
"""+source[end:]
path.write_text(source,encoding="utf-8")

transport=r"""    /** Receives JSON or Anthropic SSE on one request; NEVER auto-retries paid POSTs. */
    static JSONObject streamMessage(String address, Map<String,String> headers, JSONObject body,
                                     StreamDecoder.Listener listener) throws Exception {
        if(!address.startsWith("https://"))throw new IOException("Somente HTTPS é permitido");
        HttpURLConnection conn=(HttpURLConnection)new URL(address).openConnection();
        conn.setRequestMethod("POST");
        conn.setInstanceFollowRedirects(false);
        conn.setConnectTimeout(18000);
        conn.setReadTimeout(300000);
        conn.setRequestProperty("Accept","text/event-stream, application/json");
        conn.setRequestProperty("Content-Type","application/json; charset=utf-8");
        if(headers!=null)for(Map.Entry<String,String> h:headers.entrySet())conn.setRequestProperty(h.getKey(),h.getValue());
        conn.setDoOutput(true);
        try {
            byte[] payload=body.toString().getBytes(StandardCharsets.UTF_8);
            try(OutputStream out=conn.getOutputStream()){out.write(payload);}
            int status=conn.getResponseCode();
            if(status<200 || status>=300){
                InputStream in=conn.getErrorStream();
                String reason=in==null?"":read(in,100000);
                try {
                    JSONObject json=new JSONObject(reason);
                    JSONObject error=json.optJSONObject("error");
                    reason=error!=null?error.optString("message",error.toString()):json.optString("message",reason);
                }catch(Exception ignored){}
                throw new IOException("InfiniteModel HTTP "+status+": "+reason.substring(0,Math.min(350,reason.length())));
            }
            InputStream in=conn.getInputStream();
            String type=conn.getContentType();
            if(type==null || !type.toLowerCase(java.util.Locale.ROOT).contains("text/event-stream")){
                return new JSONObject(read(in,6000000));
            }
            StreamDecoder decoder=new StreamDecoder(listener);
            try(BufferedReader r=new BufferedReader(new InputStreamReader(in,StandardCharsets.UTF_8))){
                String line,event="";StringBuilder data=new StringBuilder();int count=0;
                while((line=r.readLine())!=null){
                    if(++count>150000)throw new IOException("Fluxo de eventos excedeu o limite");
                    if(line.isEmpty()){
                        if(data.length()>0){
                            String current=data.toString();
                            if(!"[DONE]".equals(current))decoder.event(event,new JSONObject(current));
                            data.setLength(0);event="";
                        }
                    }else if(line.startsWith("event:"))event=line.substring(6).trim();
                    else if(line.startsWith("data:")){
                        if(data.length()>0)data.append('\n');
                        data.append(line.substring(5).trim());
                    }
                }
                if(data.length()>0 && !"[DONE]".equals(data.toString()))decoder.event(event,new JSONObject(data.toString()));
            }
            return decoder.finish();
        }catch(java.net.UnknownHostException e){throw dnsError(address,e);}
        catch(java.net.SocketTimeoutException e){
            throw new IOException("A conexão com InfiniteModel parou de transmitir. A chamada pode ter sido cobrada e não será repetida automaticamente.",e);
        }finally{conn.disconnect();}
    }
"""
path=ROOT/"Net.java"
source=path.read_text(encoding="utf-8")
needle="    private static IOException dnsError(String address,Exception original){"
assert needle in source
source=source.replace(needle,transport+needle,1)
path.write_text(source,encoding="utf-8")

edit("MainActivity.java",[
    ('model="claude-opus-5", effort="default"','model="claude-sonnet-5", effort="default"'),
    ('prefs.getString("model","claude-opus-5")','prefs.getString("model","claude-sonnet-5")'),
    ('final String author,body;ChatLine(String a,String b){author=a;body=b;}',
     'final String author;String body;ChatLine(String a,String b){author=a;body=b;}'),
    ('        work("Consultando o Claude...",()->{\n            String result=agent().ask(query,selected,this::stage);\n            runOnUiThread(()->{\n                transcript.append("\\nCLAUDE\\n").append(result).append("\\n");\n                chatLines.add(new ChatLine("Claude",result));refreshChat();',
     '''        final ChatLine live=new ChatLine("Claude","Aguardando resposta da API...");
        chatLines.add(live);refreshChat();
        work("Consultando o Claude...",()->{
            AgentEngine.Progress listener=new AgentEngine.Progress(){
                private long last=0;
                public void post(String message){stage(message);}
                public void preview(String text){
                    long now=android.os.SystemClock.elapsedRealtime();
                    if(now-last<500 && text.length()<live.body.length()+500)return;
                    last=now;
                    runOnUiThread(()->{live.body=text.isEmpty()?"Recebendo resposta...":text;refreshChat();});
                }
            };
            String result=agent().ask(query,selected,listener);
            runOnUiThread(()->{
                transcript.append("\\nCLAUDE\\n").append(result).append("\\n");
                live.body=result;refreshChat();'''),
    ('{"claude-opus-5","claude-fable-5-1","claude-sonnet-5","claude-opus-5-5"}',
     '{"claude-sonnet-5","claude-opus-5","claude-fable-5-1"}'),
    ('add(body,note("Raciocínio — suporte a effort depende do gateway e modelo"),15);',
     'add(body,note("Modo compatibilidade: esforço experimental temporariamente desativado para evitar erros do gateway."),15);'),
])
path=Path("build-v03/app/build.gradle")
text=path.read_text(encoding="utf-8")
text=text.replace("versionCode 4","versionCode 5").replace("versionName '0.3.1'","versionName '0.3.2'")
path.write_text(text,encoding="utf-8")
print("v0.3.2 patch OK")
