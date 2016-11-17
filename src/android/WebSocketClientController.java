import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;

import java.io.InputStream;
import java.util.HashMap;
import java.io.File;
import java.io.FileInputStream;

//import java.security.cert.CertificateException;
public class WebSocketClientController extends CordovaPlugin {

    static final String TAG = "WebSocketClientController";
    final HashMap<String, WebSocketClient> webSocketClients;

    private enum ACTION {
        connect, send, close
    }

    /**
     * Constructor.
     */
    public WebSocketClientController() {
        this.webSocketClients = new HashMap<String, WebSocketClient>();
    }

    @Override
    public boolean execute(String action, JSONArray arguments, CallbackContext callbackContext) throws JSONException {
        switch (ACTION.valueOf(action)) {
            case connect:
                return this.connect(
                        arguments.getString(0),
                        arguments.getString(1),
                        arguments.getString(2),
                        callbackContext
                );
            case send:
                return this.send(
                        arguments.getString(0),
                        arguments.getString(1),
                        callbackContext
                );
            case close:
                return this.close(
                        arguments.getString(0),
                        callbackContext
                );
            default:
                callbackContext.error("Invalid action: " + action);
                return false;
        }
    }

    private boolean connect(String url, String certFilePath, String certFilePassword, CallbackContext callbackContext) {
        try {
            InputStream certFileStream = null;
            if (certFilePath.length() > 0) {
                File file = new File(certFilePath);
                certFileStream = new FileInputStream(file);
            }

            WebSocketClient client = WebSocketClientFactory.createClient(url, certFileStream, certFilePassword);
            client.connect(callbackContext);
            webSocketClients.put(client.getId(), client);

            return true;
        } catch (Exception e) {
            callbackContext.error(e.getMessage());
            return false;
        }
    }

    private boolean send(String resourceId, String message, CallbackContext callbackContext) {

        if (!webSocketClients.containsKey(resourceId)) {
            callbackContext.error("Unknown resourceId " + resourceId + " given!");
            return false;
        } else {
            webSocketClients.get(resourceId).send(message);
            callbackContext.success();
            return true;
        }
    }

    private boolean close(String resourceId, CallbackContext callbackContext) {
        if (!webSocketClients.containsKey(resourceId)) {
            callbackContext.error("Unknown resourceId " + resourceId + " given!");
            return false;
        } else {
            WebSocketClient client = webSocketClients.get(resourceId);
            client.close();

            webSocketClients.remove(resourceId);
            callbackContext.success();
            return true;
        }
    }
}