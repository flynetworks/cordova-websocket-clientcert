import android.util.JsonWriter;
import org.java_websocket.handshake.ServerHandshake;
import android.util.Log;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;

import java.io.IOException;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.StringWriter;
import java.net.URI;
import java.util.UUID;

class WebSocketClient extends org.java_websocket.client.WebSocketClient {

    private String id;
    private CallbackContext callbackContext;

    WebSocketClient(URI serverUri) {
        super(serverUri);
    }

    void connect(CallbackContext callbackContext) {
        this.id = UUID.randomUUID().toString();
        this.callbackContext = callbackContext;
        super.connect();
    }

    public String getId() {
        return this.id;
    }

    @Override
    public void onOpen(ServerHandshake handshakedata) {

        StringWriter stringWriter = new StringWriter();
        JsonWriter writer = new JsonWriter(stringWriter);

        try {
            writer.beginObject();
            writer.name("event").value("onOpen");
            writer.name("resourceId").value(this.id);
            writer.endObject();
        } catch (IOException e) {
            e.printStackTrace();
        }

        this.callback(PluginResult.Status.OK, stringWriter.toString());
    }

    @Override
    public void onMessage(String message) {

        StringWriter stringWriter = new StringWriter();
        JsonWriter writer = new JsonWriter(stringWriter);

        try {
            writer.beginObject();
            writer.name("event").value("onMessage");
            writer.name("message").value(message);
            writer.endObject();
        } catch (IOException e) {
            e.printStackTrace();
        }

        this.callback(PluginResult.Status.OK, stringWriter.toString());
    }

    @Override
    public void onClose(int code, String reason, boolean remote) {
        StringWriter stringWriter = new StringWriter();
        JsonWriter writer = new JsonWriter(stringWriter);

        try {
            writer.beginObject();
            writer.name("event").value("onClose");
            writer.name("code").value(code);
            writer.name("reason").value(reason);
            writer.name("remote").value(remote);
            writer.endObject();
        } catch (IOException e) {
            e.printStackTrace();
        }

        this.callback(PluginResult.Status.OK, stringWriter.toString());
    }

    @Override
    public void onError(Exception ex) {
        StringWriter stringWriter = new StringWriter();
        JsonWriter writer = new JsonWriter(stringWriter);

        try {
            writer.beginObject();
            writer.name("event").value("onError");
            writer.name("errorMessage").value(ex.getMessage());
            writer.endObject();
        } catch (IOException e) {
            e.printStackTrace();
        }

        this.callback(PluginResult.Status.OK, stringWriter.toString());
    }

    private void callback(PluginResult.Status status, String message) {
        PluginResult result = new PluginResult(status, message);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
    }
}