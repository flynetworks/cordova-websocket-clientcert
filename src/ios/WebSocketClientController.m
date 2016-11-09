/********* WebSocketClientController.m Cordova Plugin Implementation *******/

#import "WebSocketClientController.h"
#import <Cordova/CDVPlugin.h>
#import "JFRWebSocket.h"

@implementation WebSocketClientController

- (void) connect:(CDVInvokedUrlCommand*)command
{
//    self.socket = [[JFRWebSocket alloc] initWithURL:[NSURL URLWithString:@"wss://sandbox.kaazing.net/echo"] protocols:@[]];
//    self.socket.delegate = self;
//    [self.socket connect];
    [self open];
}

- (void)open {

//    NSURL *serverURL = [NSURL URLWithString: @"http://192.168.0.17:9000"];

    NSMutableURLRequest *connectionRequest = [
        NSMutableURLRequest requestWithURL:serverURL
        cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0
    ];

    [[NSURLConnection alloc] initWithRequest:connectionRequest delegate:self];
}

/* NSURLConnection Delegate Methods */

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"in didReceiveResponse ");
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSLog(@"in didReceiveData ");
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return YES;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSLog(@"in didReceiveAuthenticationChallenge ");
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSLog(@"in willSendRequestForAuthenticationChallenge ");
    if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        NSLog(@"Ignoring SSL");
        SecTrustRef trust = challenge.protectionSpace.serverTrust;
        NSURLCredential *cred;
        cred = [NSURLCredential credentialForTrust:trust];
        [challenge.sender useCredential:cred forAuthenticationChallenge:challenge];
        return;
    }

    if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate])
    {

        NSString *appFolderPath = [[NSBundle mainBundle] resourcePath];
        NSString *certFile = [NSString stringWithFormat:@"%@/%@", appFolderPath, @"www/sma2client2.p12"];


        NSString *thePath = certFile;
        NSData *PKCS12Data = [[NSData alloc] initWithContentsOfFile:thePath];
        CFDataRef inPKCS12Data = (__bridge CFDataRef)PKCS12Data;
        SecIdentityRef identity;
        [self extractIdentity :inPKCS12Data :&identity];

        SecCertificateRef certificate = NULL;
        SecIdentityCopyCertificate (identity, &certificate);

        const void *certs[] = {certificate};
        CFArrayRef certArray = CFArrayCreate(kCFAllocatorDefault, certs, 1, NULL);

        NSURLCredential *credential = [NSURLCredential credentialWithIdentity:identity certificates:(__bridge NSArray*)certArray persistence:NSURLCredentialPersistencePermanent];
        [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
    }
    // Provide your regular login credential if needed...
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"in connectionDidFinishLoading ");
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"in didFailWithError %@", error);
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;     // Never cache
}

- (OSStatus)extractIdentity:(CFDataRef)inP12Data :(SecIdentityRef*)identity {
    OSStatus securityError = errSecSuccess;

    CFStringRef password = CFSTR("PASSWORD");
    const void *keys[] = { kSecImportExportPassphrase };
    const void *values[] = { password };

    CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);

    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    securityError = SecPKCS12Import(inP12Data, options, &items);

    if (securityError == 0) {
        CFDictionaryRef ident = CFArrayGetValueAtIndex(items,0);
        const void *tempIdentity = NULL;
        tempIdentity = CFDictionaryGetValue(ident, kSecImportItemIdentity);
        *identity = (SecIdentityRef)tempIdentity;
    }

    if (options) {
        CFRelease(options);
    }

    return securityError;
}

/***********************************************************************************************************************
- (void)connectObsolte:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSString* url = [command.arguments objectAtIndex:0];
    NSString* certFilePath = [command.arguments objectAtIndex:1];
    NSString* certFilePassword = [command.arguments objectAtIndex:2];

    NSString *appFolderPath = [[NSBundle mainBundle] resourcePath];
    NSString *certFile = [NSString stringWithFormat:@"%@/%@", appFolderPath, @"www/sma2client2.p12"];
    NSString *certFilePublic = [NSString stringWithFormat:@"%@/%@", appFolderPath, @"www/sma2client2.crt"];

    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:certFile]){
        NSLog(@"Certificate file was found: %@", certFile);

        NSData *certData = [NSData dataWithContentsOfFile:certFile];
//        SecCertificateRef cert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certData);

        NSData *PKCS12Data = [NSData dataWithContentsOfFile:certFile];
        CFDataRef inPKCS12Data = (__bridge CFDataRef)PKCS12Data;
        CFStringRef password = CFSTR("aT7kyG");

        const void *keys[] = { kSecImportExportPassphrase };
        const void *values[] = { password };

        CFDictionaryRef optionsDictionary = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
        CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
        OSStatus securityError = SecPKCS12Import(inPKCS12Data, optionsDictionary, &items);
        NSArray *keystore = (__bridge_transfer NSArray *)items;

        if (securityError == 0) {
            NSLog(@"Certificate file imported successfully ====== %@", certFile);

            CFDictionaryRef myIdentityAndTrust = CFArrayGetValueAtIndex (items, 0);

            const void *identity = NULL;

            identity = CFDictionaryGetValue (myIdentityAndTrust, kSecImportItemIdentity);

            SecCertificateRef cert = NULL;
            SecIdentityCopyCertificate (identity, &cert);
            if (cert != NULL) {
                SecTrustRef trust = NULL;
                SecPolicyRef policy = SecPolicyCreateBasicX509();
//                SecPolicyRef policy = SecPolicyCreateSSL(true, CFSTR("SOMEHOST.COM"));

                NSArray *myCerts = [[NSArray alloc] initWithObjects:(__bridge id) identity, (__bridge id) cert, nil];

                if (policy) {
                    if (SecTrustCreateWithCertificates(cert, policy, &trust) == noErr) {
                        SecTrustResultType result;
                        SecTrustEvaluate(trust, &result);


                        //Check the result of the trust evaluation rather than the result of the API invocation.
//                        if (true || result == kSecTrustResultProceed || result == kSecTrustResultUnspecified) {
                        SecKeyRef key = SecTrustCopyPublicKey(trust);

                        self.socket = [[JFRWebSocket alloc] initWithURL:[NSURL URLWithString:url] protocols:@[@"chat", @"superchat"]];
                        self.socket.security = [[JFRSecurity alloc] initWithCerts:@[[[JFRSSLCert alloc] initWithKey:key]] publicKeys:YES];;
                        self.socket.delegate = self;
                        [self.socket connect];
//                        } else {
//                            NSLog(@"Trust failed ====== %@", SecTrustGetTrustResult(trust, result));
//                        }
                    }
                }
            }
        } else {
            NSLog(@"Error while importing pkcs12 [%ld]", securityError);
        }


        //////////////



        /////////////


//        CFDataRef inPKCS12Data = (__bridge CFDataRef)PKCS12Data;
//        CFStringRef password = CFSTR("aT7kyG");
//
//        const void *keys[] = { kSecImportExportPassphrase };
//        const void *values[] = { password };
//
//        CFDictionaryRef optionsDictionary = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
//        CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
//        OSStatus securityError = SecPKCS12Import(inPKCS12Data, optionsDictionary, &items);
//        NSArray *keystore = (__bridge_transfer NSArray *)items;

//        if (securityError == 0) {
//            NSLog(@"Certificate file imported successfully ====== %@", certFile);
//
//            CFDictionaryRef myIdentityAndTrust = CFArrayGetValueAtIndex (items, 0);
//
//            const void *tempTrust = NULL;
//            const void *identity = NULL;
//
//            identity = CFDictionaryGetValue (myIdentityAndTrust, kSecImportItemIdentity);
//
//            SecCertificateRef certificate = NULL;
//            SecIdentityCopyCertificate (identity, &certificate);
//        }

//        JFRSSLCert *cert = [[JFRSSLCert alloc] initWithData:PKCS12DataPublic];
//        JFRSecurity *security = [[JFRSecurity alloc] initWithCerts:cert publicKeys:NO];
//
//        SecKeyRef
//
//        NSLog(@"EOS: %@", certFile);
//
//        self.socket = [[JFRWebSocket alloc] initWithURL:[NSURL URLWithString:url] protocols:@[@"chat",@"superchat"]];
//        self.socket.security = security;
//        self.socket.delegate = self;
//        [self.socket connect];
    } else {
        NSLog(@"Certificate file not found: %@", certFile);
    }

//
//    NSError * error;
//    NSArray * directoryContents =  [[NSFileManager defaultManager]
//            contentsOfDirectoryAtPath:certFilePath error:&error];
//
//    NSLog(@"directoryContents ====== %@",directoryContents);


    / *
    self.socket.security = [[JFRSecurity alloc] initWithCerts:@[[[JFRSSLCert alloc] initWithData:p12data]] publicKeys:YES];
    //    SecPKCS12Import()
    self.socket.delegate = self;
    [self.socket connect];
    * /
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
***********************************************************************************************************************/

-(void)websocketDidConnect:(JFRWebSocket*)socket {
    NSLog(@"websocket is connected");
}

-(void)websocketDidDisconnect:(JFRWebSocket*)socket error:(NSError*)error {
    NSLog(@"websocket is disconnected: %@",[error localizedDescription]);
}

-(void)websocket:(JFRWebSocket*)socket didReceiveMessage:(NSString*)string {
    NSLog(@"got some text: %@",string);
}

-(void)websocket:(JFRWebSocket*)socket didReceiveData:(NSData*)data {
    NSLog(@"got some binary data: %d",data.length);
}

@end