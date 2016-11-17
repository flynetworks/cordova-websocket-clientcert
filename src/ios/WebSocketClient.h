#import <Cordova/CDVPlugin.h>
#import "flyfire/JFRWebSocket.h"

@class WebSocketClient;

/**
 It is important to note that all the delegate methods are put back on the main thread.
 This means if you want to do some major process of the data, you need to create a background thread.
 */
@protocol WebSocketClientDelegate <NSObject>

@optional

/**
 * The connected connected to its host.
 *
 * @param uuid The unique id of the client.
 * @param client The current client object.
 */
- (void)clientDidConnect:(nonnull NSString *)uuid client:(nonnull WebSocketClient *)client;

/**
 * The client was disconnected from its host.
 *
 * @param uuid The unique id of the client.
 * @param client The current client object.
 * @param error The error occured to trigger the disconnect.
 */
- (void)clientDidDisconnect:(nonnull NSString *)uuid client:(nonnull WebSocketClient *)client error:(nullable NSError *)error;

/**
 * The client got a text based message.
 *
 * @param uuid The unique id of the client.
 * @param client The current client object.
 * @param string The raw text data that has been returned.
 */
- (void)websocket:(nonnull NSString *)uuid client:(nonnull WebSocketClient *)client didReceiveMessage:(nonnull NSString *)string;

/**
 * The client got a binary based message.
 *
 * @param uuid The unique id of the client.
 * @param client The current client object.
 * @param string The raw binary data that has been returned.
 */
- (void)websocket:(nonnull NSString *)uuid client:(nonnull WebSocketClient *)client didReceiveData:(nullable NSData *)data;

@end

@interface WebSocketClient : NSObject <JFRWebSocketDelegate>

@property(nonatomic, strong, nonnull) JFRWebSocket *socket;
@property(nonatomic, strong, nonnull) NSString *uuid;
@property(nonatomic, strong, nonnull) CDVInvokedUrlCommand *command;
@property(nonatomic, weak, nullable) id <WebSocketClientDelegate> delegate;

- (nonnull id)initWithURL:(nonnull NSURL *)url command:(CDVInvokedUrlCommand *)command pkcs12Path:(nullable NSString *)pkcs12Path password:(nullable NSString *)password;
- (void)send:(nonnull NSString *)message;
- (void)close;
@end