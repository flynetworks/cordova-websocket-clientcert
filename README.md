# cordova-websocket-clientcert

This plugin provides a custom websocket implemenation for javascript
supporting client side PKCS12 certificates.

## Supported platforms
* android
* ios

## Installation

cordova plugin add CordovaWebSocketClientCert

## Note

For the time being all servers are trusted

## Usage

```javascript
var url = 'wss://hostname:port/path'; 
var certFile = '/absolute/path/myCert.p12'; // absolute path of the filesystem (see https://cordova.apache.org/docs/en/latest/reference/cordova-plugin-file/#android-file-system-layout)
var certPass = 'Secure123';

var ws = new WebSocketClient(url, certFile, certPass);
ws.onopen = function () {
    //socket open
}

ws.onclose = function () {
    //socket closed
}

ws.onerror = function () {
    //socket error
}

ws.onmessage = function (message) {
    var data = message.data;
}

ws.send(JSON.stringify({a: 1, b: 2}), function () {
    //success callback
}, function () {
    //error callback
});
```

Example using "cordova-plugin-file":

```javascript
resolveLocalFileSystemURL(cordova.file.applicationStorageDirectory, function (dirEntry) {
    var certPath = dirEntry.fullPath  + 'myCert.p12';
    var ws = new WebSocketClient('wss://hostname:port/path', certPath, 'somePassword');

    ...
}, console.log);
```