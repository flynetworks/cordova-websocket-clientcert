#import <Cordova/CDVPlugin.h>
#import "WebSocketClient.h"

@class WebSocketClient;

@interface WebSocketClientController : CDVPlugin <WebSocketClientDelegate>

@property(nonatomic, strong) NSMutableDictionary *clients;
@property(nonatomic, strong) WebSocketClient *client;

- (void)connect:(CDVInvokedUrlCommand *)command;

@end