#import "WebSocketClient.h"

@implementation WebSocketClient {
}

- (id)initWithURL:(NSURL *)url command:(CDVInvokedUrlCommand *)command pkcs12Path:(NSString *)pkcs12Path password:(NSString *)password {

    self.command = command;
    self.uuid = [[NSUUID UUID] UUIDString];
    self.socket = [[JFRWebSocket alloc] initWithURL:url protocols:NULL];
    self.socket.selfSignedSSL = YES;

    if (pkcs12Path.length > 0) {
        [self.socket loadClientCertificate:pkcs12Path password:password];
    }

    self.socket.delegate = self;
    [self.socket connect];
    return self;
}

- (void)send:(NSString *)message {
    [self.socket writeString:message];
}

- (void)close {
    [self.socket disconnect];
}

- (void)websocketDidConnect:(JFRWebSocket *)socket {
    if([self.delegate respondsToSelector:@selector(clientDidConnect:client:)]) {
        [self.delegate clientDidConnect:self.uuid client:self];
    }
}

- (void)websocketDidDisconnect:(JFRWebSocket *)socket error:(NSError *)error {
    if([self.delegate respondsToSelector:@selector(clientDidDisconnect:client:error:)]) {
        [self.delegate clientDidDisconnect:self.uuid client:self error:error];
    }
}

- (void)websocket:(JFRWebSocket *)socket didReceiveMessage:(NSString *)string {
    if([self.delegate respondsToSelector:@selector(websocket:client:didReceiveMessage:)]) {
        [self.delegate websocket:self.uuid client:self didReceiveMessage:string];
    }
}

- (void)websocket:(JFRWebSocket *)socket didReceiveData:(NSData *)data {
    if([self.delegate respondsToSelector:@selector(websocket:client:didReceiveData:)]) {
        [self.delegate websocket:self.uuid client:self didReceiveData:data];
    }
}

@end