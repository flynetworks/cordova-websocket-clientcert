/********* WebSocketClientController.m Cordova Plugin Implementation *******/

#import "WebSocketClientController.h"

@interface WebSocketClientController ()

- (NSString *)getJSONString:(NSString *) dict;
@end

@implementation WebSocketClientController {
}

- (void)pluginInitialize {
    self.clients = [[NSMutableDictionary alloc] init];
}

- (void)connect:(CDVInvokedUrlCommand *)command {
    NSURL *url = [NSURL URLWithString:command.arguments[0]];
    WebSocketClient *client = [[WebSocketClient alloc]
            initWithURL:url
                command:command
             pkcs12Path:command.arguments[1]
               password:command.arguments[2]
    ];

    client.delegate = self;
    self.clients[client.uuid] = client;
}

- (void)send:(CDVInvokedUrlCommand *)command {
    WebSocketClient *client = self.clients[command.arguments[0]];
    [client send:command.arguments[1]];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)close:(CDVInvokedUrlCommand *)command {
    WebSocketClient *client = self.clients[command.arguments[0]];
    [client close];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)clientDidConnect:(NSString *)uuid client:(WebSocketClient *)client {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    [dict setValue:@"onOpen" forKey:@"event"];
    [dict setValue:uuid forKey:@"resourceId"];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[self getJSONString:dict]];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:client.command.callbackId];
}

- (void)clientDidDisconnect:(NSString *)uuid client:(WebSocketClient *)client error:(NSError *)error {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    [dict setValue:@"onClose" forKey:@"event"];

    [dict setValue:@(error.code) forKey:@"code"];
    [dict setValue:error.localizedFailureReason forKey:@"reason"];
    [dict setValue:[NSString stringWithUTF8String:error.code == 61 ? "true" : "false"] forKey:@"remote"];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[self getJSONString:dict]];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:client.command.callbackId];
}

- (void)websocket:(NSString *)uuid client:(WebSocketClient *)client didReceiveMessage:(NSString *)string {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    [dict setValue:@"onMessage" forKey:@"event"];
    [dict setValue:string forKey:@"message"];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[self getJSONString:dict]];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:client.command.callbackId];
}

- (void)websocket:(NSString *)uuid client:(WebSocketClient *)client didReceiveData:(NSData *)data {

}

- (NSString *)getJSONString:(NSString *) dict {
    NSError *err;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&err];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
