#import <Cordova/CDVPlugin.h>
#import "JFRWebSocket.h"

@interface WebSocketClientController : CDVPlugin <NSURLSessionDelegate>

- (void)connect:(CDVInvokedUrlCommand*)command;

@end