import org.java_websocket.client.DefaultSSLWebSocketClientFactory;

import javax.net.ssl.*;
import javax.security.cert.X509Certificate;
import java.io.InputStream;
import java.net.URI;
import java.security.KeyStore;
import java.security.cert.CertificateException;

class WebSocketClientFactory {

    public static WebSocketClient createClient(String url, InputStream certFile, String certFilePassword) throws Exception {
        WebSocketClient client = new WebSocketClient(new URI(url));

        if (certFile != null) {
            SSLContext context = SSLContext.getInstance("TLSv1.2");

            context.init(
                    WebSocketClientFactory.createKeyManager(certFile, certFilePassword),
                    WebSocketClientFactory.createTrustManager(),
                    null
            );

            client.setWebSocketFactory(new DefaultSSLWebSocketClientFactory(context));
        }

        return client;
    }

    private static TrustManager[] createTrustManager() {
        TrustManager[] trustAllCerts = new TrustManager[]{new X509TrustManager() {
            @Override
            public void checkClientTrusted(java.security.cert.X509Certificate[] chain, String authType) throws CertificateException {

            }

            @Override
            public void checkServerTrusted(java.security.cert.X509Certificate[] chain, String authType) throws CertificateException {

            }

            public java.security.cert.X509Certificate[] getAcceptedIssuers() {
                return null;
            }

            public void checkClientTrusted(X509Certificate[] certs, String authType) {
            }

            public void checkServerTrusted(X509Certificate[] certs, String authType) {
            }

        }};
        return trustAllCerts;
    }

    private static KeyManager[] createKeyManager(InputStream certFile, String certFilePassword) throws Exception {

        String algorithm = KeyManagerFactory.getDefaultAlgorithm();
        KeyManagerFactory factory = KeyManagerFactory.getInstance(algorithm);
        factory.init(WebSocketClientFactory.createKeyStore(certFile, certFilePassword), certFilePassword.toCharArray());

        return factory.getKeyManagers();
    }

    private static KeyStore createKeyStore(InputStream certFile, String certFilePassword) throws Exception {
        KeyStore keyStore = KeyStore.getInstance("PKCS12");

        if (certFile != null) {
            keyStore.load(certFile, certFilePassword.toCharArray());
        }

        return keyStore;
    }
}