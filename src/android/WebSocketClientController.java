import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;

import java.io.InputStream;
import java.util.HashMap;

//import java.security.cert.CertificateException;
public class WebSocketClientController extends CordovaPlugin {

    static final String TAG = "WebSocketClientController";
    final HashMap<String, WebSocketClient> webSocketClients;

    private enum ACTION {
        connect, send
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
            default:
                callbackContext.error("Invalid action: " + action);
                return false;
        }
    }

    private boolean connect(String url, String certFilePath, String certFilePassword, CallbackContext callbackContext) {
        try {
            InputStream certFileStream = null;
            if (certFilePath.length() > 0) {
                certFileStream = cordova.getActivity().getApplicationContext().getAssets().open(certFilePath);
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
        } else {
            webSocketClients.get(resourceId).send(message);
            callbackContext.success();
        }

        return true;
    }
}