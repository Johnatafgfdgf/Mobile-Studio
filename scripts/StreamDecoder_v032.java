package com.claudemobilestudio.app;

import java.io.IOException;
import java.util.Map;
import java.util.TreeMap;
import org.json.JSONArray;
import org.json.JSONObject;

/** Reconstructs Anthropic Messages SSE events into a normal message. */
final class StreamDecoder {
    interface Listener { void onText(String text); }
    private static class Block {
        JSONObject json;
        StringBuilder text=new StringBuilder();
        StringBuilder args=new StringBuilder();
        Block(JSONObject json){ this.json=json; }
    }
    private final TreeMap<Integer,Block> blocks=new TreeMap<>();
    private final StringBuilder visible=new StringBuilder();
    private final Listener listener;
    private boolean complete=false;
    private String reason="";
    private int lastProgress=0;
    StreamDecoder(Listener listener){this.listener=listener;}

    void event(String name,JSONObject payload) throws Exception {
        String type=payload.optString("type",name);
        if("error".equals(type)){
            JSONObject error=payload.optJSONObject("error");
            throw new IOException("Erro do stream: "+(error==null?payload.toString():error.optString("message",error.toString())));
        }
        if("content_block_start".equals(type)){
            int index=payload.optInt("index",-1);
            JSONObject value=payload.optJSONObject("content_block");
            if(index<0 || index>128 || value==null)throw new IOException("Bloco SSE inválido");
            Block block=new Block(new JSONObject(value.toString()));
            if("text".equals(value.optString("type")))block.text.append(value.optString("text",""));
            blocks.put(index,block);
        } else if("content_block_delta".equals(type)){
            Block block=blocks.get(payload.optInt("index",-1));
            JSONObject delta=payload.optJSONObject("delta");
            if(block==null||delta==null)return;
            if("text_delta".equals(delta.optString("type"))){
                String next=delta.optString("text","");
                if(block.text.length()+next.length()>600000)throw new IOException("Limite de texto atingido");
                block.text.append(next);
                visible.append(next);
                if(visible.length()-lastProgress>180 || next.contains("\n")){
                    lastProgress=visible.length();
                    if(listener!=null)listener.onText(visible.toString());
                }
            }else if("input_json_delta".equals(delta.optString("type"))){
                String fragment=delta.optString("partial_json","");
                if(block.args.length()+fragment.length()>250000)throw new IOException("Entrada de ferramenta muito grande");
                block.args.append(fragment);
            }
        } else if("content_block_stop".equals(type)){
            Block block=blocks.get(payload.optInt("index",-1));
            if(block!=null)finishBlock(block);
        } else if("message_delta".equals(type)){
            JSONObject delta=payload.optJSONObject("delta");
            if(delta!=null)reason=delta.optString("stop_reason","");
        } else if("message_stop".equals(type))complete=true;
    }
    private void finishBlock(Block b) throws Exception {
        if("text".equals(b.json.optString("type")))b.json.put("text",b.text.toString());
        if("tool_use".equals(b.json.optString("type"))){
            if(b.args.length()>0)b.json.put("input",new JSONObject(b.args.toString()));
            else if(!b.json.has("input"))b.json.put("input",new JSONObject());
        }
    }
    JSONObject finish() throws Exception {
        if(!complete)throw new IOException("Resposta interrompida antes da confirmação final; não será reenviada automaticamente para evitar cobranças duplicadas.");
        JSONArray content=new JSONArray();
        for(Map.Entry<Integer,Block> e:blocks.entrySet()){
            finishBlock(e.getValue());
            content.put(e.getValue().json);
        }
        if(listener!=null)listener.onText(visible.toString());
        if(content.length()==0)throw new IOException("Resposta vazia da API; nenhuma repetição automática.");
        return new JSONObject().put("content",content).put("stop_reason",reason);
    }
}