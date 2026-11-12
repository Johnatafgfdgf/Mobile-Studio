from pathlib import Path

base=Path("build-v03")
src=base/"app/src/main/java/com/claudemobilestudio/app"
def change(p, before, after):
    text=p.read_text(encoding="utf-8")
    if before not in text:
        raise RuntimeError(f"Expected anchor not found in {p}: {before[:100]}")
    p.write_text(text.replace(before,after,1),encoding="utf-8")

net=src/"Net.java"
change(net,
    '    static JSONObject json(String method, String address, Map<String,String> headers, JSONObject body) throws Exception {\n',
    '    static JSONObject json(String method, String address, Map<String,String> headers, JSONObject body) throws Exception {\n'
    '        return json(method,address,headers,body,90000);\n'
    '    }\n'
    '    static JSONObject json(String method, String address, Map<String,String> headers, JSONObject body, int readTimeoutMs) throws Exception {\n'
    '        if(readTimeoutMs<10000 || readTimeoutMs>360000) throw new IllegalArgumentException("Timeout inválido");\n'
)
change(net, 'conn.setConnectTimeout(18000);\n        conn.setReadTimeout(90000);',
           'conn.setConnectTimeout(25000);\n        conn.setReadTimeout(readTimeoutMs);')
change(net, 'throw new IOException("Tempo de conexão esgotado em "+new URL(address).getHost()+". Verifique sua internet ou tente novamente.",ex);',
           'throw new IOException("Tempo de resposta esgotado em "+new URL(address).getHost()+". A solicitação pode já ter sido processada; use Retomar tarefa após conferir a conexão.",ex);')

eng=src/"AgentEngine.java"
change(eng, '    private final JSONArray messages=new JSONArray();',
            '    private final JSONArray messages=new JSONArray();\n    private boolean pendingTask=false;')
change(eng, '    String model(){return model;}\n',
    '    String model(){return model;}\n'
    '    boolean hasPendingTask(){return pendingTask;}\n'
    '    private File pendingFile(){return new File(conversationFile().getPath()+".pending");}\n'
    '    private void setPending(boolean p){pendingTask=p;if(p){try{pendingFile().createNewFile();}catch(IOException ignored){}}else{pendingFile().delete();}}\n')
change(eng, 'conversationFile().delete(); staged.clear();',
           'conversationFile().delete(); setPending(false); staged.clear();')
change(eng, '        if(key.isEmpty()) throw new IllegalStateException("Configure a chave InfiniteModel em Configurações");',
           '        if(pendingTask) throw new IllegalStateException("Há uma tarefa incompleta. Use Retomar tarefa ou Nova conversa.");\n'
           '        if(key.isEmpty()) throw new IllegalStateException("Configure a chave InfiniteModel em Configurações");')
change(eng,
    '        messages.put(new JSONObject().put("role","user").put("content",userBlocks));\n        saveHistory();\n        StringBuilder finalText=new StringBuilder();',
    '        messages.put(new JSONObject().put("role","user").put("content",userBlocks));\n'
    '        saveHistory();setPending(true);\n'
    '        return process(progress);\n'
    '    }\n'
    '    String resume(Progress progress) throws Exception {\n'
    '        if(!pendingTask || messages.length()==0) throw new IllegalStateException("Não há tarefa interrompida.");\n'
    '        if(key.isEmpty()) throw new IllegalStateException("Configure sua chave InfiniteModel.");\n'
    '        progress.post("Retomando a tarefa com as ferramentas já concluídas");\n'
    '        return process(progress);\n'
    '    }\n'
    '    private String process(Progress progress) throws Exception {\n'
    '        StringBuilder finalText=new StringBuilder();'
)
change(eng, '            JSONObject resp=callApi();', '            JSONObject resp=callApi(progress);')
change(eng, '                trimHistory();saveHistory();\n                progress.post("Resposta final recebida;',
            '                trimHistory();saveHistory();setPending(false);\n                progress.post("Resposta final recebida;')
change(eng, '    private JSONObject callApi() throws Exception {',
           '    private JSONObject callApi(Progress progress) throws Exception {')
change(eng, '        return Net.json("POST",gateway,h,payload);',
            '        progress.post("Aguardando a InfiniteModel; tarefas complexas podem levar vários minutos");\n'
            '        return Net.json("POST",gateway,h,payload,300000);')
change(eng, '    private void loadHistory() {\n        File f=conversationFile();if(!f.isFile())return;',
           '    private void loadHistory() {\n        File f=conversationFile();\n'
           '        pendingTask=f.isFile() && pendingFile().isFile();\n'
           '        if(!f.isFile())return;')

ui=src/"MainActivity.java"
change(ui, '        activityPanel();\n        if(!attachments.isEmpty()){',
           '        activityPanel();\n'
           '        add(body,button("↻ Retomar tarefa interrompida",this::resumeTask),9);\n'
           '        add(body,note("Retoma as etapas já salvas. Uma nova solicitação pode consumir créditos."),5);\n'
           '        if(!attachments.isEmpty()){')
change(ui, '    private void confirmNewChat(){',
    '    private void resumeTask(){\n'
    '        if(busy)return;\n'
    '        try{if(!agent().hasPendingTask()){\n'
    '            dialog("Nenhuma tarefa pendente","Não há tarefa interrompida neste repositório e modelo.");return;\n'
    '        }}catch(Exception e){dialog("Erro ao retomar",e.getMessage());return;}\n'
    '        new AlertDialog.Builder(this).setTitle("Retomar a análise?")\n'
    '            .setMessage("As etapas salvas serão reutilizadas. A solicitação que expirou pode ter sido processada e cobrada pela InfiniteModel.")\n'
    '            .setNegativeButton("Cancelar",null)\n'
    '            .setPositiveButton("Retomar",(d,w)->work("Retomando análise...",()->{\n'
    '                String result=agent().resume(this::stage);\n'
    '                runOnUiThread(()->{\n'
    '                    transcript.append("\\nCLAUDE\\n").append(result).append("\\n");\n'
    '                    chatLines.add(new ChatLine("Claude",result));refreshChat();\n'
    '                    toast("Análise retomada");\n'
    '                });\n'
    '            })).show();\n'
    '    }\n'
    '    private void confirmNewChat(){')
change(base/"app/build.gradle","versionCode 3","versionCode 4")
change(base/"app/build.gradle","versionName '0.3.0'","versionName '0.3.1'")
print("Applied v0.3.1 timeout and resume patch")
