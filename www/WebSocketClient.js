['CONNECTING', 'OPEN', 'CLOSED', 'CLOSING'].forEach(function (p) {
    WebSocketClient[p] = WebSocket[p];
});

function WebSocketClient(url, p12File, password) {
    this.readyState = null;
    this.resourceId = null;

    var nullFn = function () {};

    this.onopen = nullFn;
    this.onclose = nullFn;
    this.onerror = nullFn;
    this.onmessage = nullFn;

    setTimeout(this.connect.bind(this, url, p12File, password), 0);
}

WebSocketClient.prototype.connect = function (url, p12File, password) {
    this.readyState = WebSocket.CONNECTING;

    Cordova.exec(
        this.onConnectionEvent.bind(this),
        this.onConnectionFailed.bind(this),
        "WebSocketClientController",
        "connect",
        [url, p12File ? p12File : '', password]
    );
};

WebSocketClient.prototype.onConnectionFailed = function (error) {
    this.readyState = WebSocketClient.CLOSED;
    throw new Error(error);
};

WebSocketClient.prototype.send = function (message, success, error) {
    if (this.readyState !== WebSocketClient.OPEN) {
        throw "Unable to send data in readyState " + this.readyState;
    }

    var nullFn = function () {};

    Cordova.exec(
        (success || nullFn).bind(this),
        (error || nullFn).bind(this),
        "WebSocketClientController",
        "send",
        [this.resourceId, message]
    );
};

WebSocketClient.prototype.close = function (message, success, error) {
    if (this.readyState !== WebSocketClient.OPEN) {
        throw "Unable to close websocket in readyState " + this.readyState;
    }

    var nullFn = function () {};

    Cordova.exec(
        (success || nullFn).bind(this),
        (error || nullFn).bind(this),
        "WebSocketClientController",
        "close",
        [this.resourceId]
    );
};

WebSocketClient.prototype.onConnectionEvent = function (jsonStr) {

    var json = JSON.parse(jsonStr);

    switch (json.event) {
        case "onOpen":
            this.readyState = WebSocketClient.OPEN;
            this.resourceId = json.resourceId;
            this.onopen(new Event('open'));
            break;

        case "onClose":
            this.readyState = WebSocketClient.CLOSED;
            this.onclose(new Event('close'));
            break;

        case "onMessage":
            this.onmessage(new MessageEvent("message", {
               data: json.message
            }));
            break;
        case "onError":
            this.onerror(new Error("error"));
            break;
        default:
            break;
    }
};

module.exports = WebSocketClient;