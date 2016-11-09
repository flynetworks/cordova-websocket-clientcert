/********* WebSocketClientController.h Cordova Plugin Header *******/

#import <Cordova/CDVPlugin.h>
#import "JFRWebSocket.h"

@interface WebSocketClientController : CDVPlugin <JFRWebSocketDelegate>

@property(nonatomic, strong) JFRWebSocket *socket;

- (void)connect:(CDVInvokedUrlCommand*)command;

- (void)websocketDidConnect:(JFRWebSocket *)socket;

- (void)websocketDidDisconnect:(JFRWebSocket *)socket error:(NSError *)error;

- (void)websocket:(JFRWebSocket *)socket didReceiveMessage:(NSString *)string;

- (void)websocket:(JFRWebSocket *)socket didReceiveData:(NSData *)data;

@end