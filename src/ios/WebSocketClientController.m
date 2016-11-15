/********* WebSocketClientController.m Cordova Plugin Implementation *******/

#import "WebSocketClientController.h"
#import <Cordova/CDVPlugin.h>
#import "JFRWebSocket.h"

@interface WebSocketClientController ()
- (void)loadPKCS12File;

- (void)createCredential;
@end

@implementation WebSocketClientController {
    NSURL *serverURL;
    NSString *appFolderPath;
    NSString *pkcs12Path;
    NSString *password;

    SecIdentityRef identityRef;
    CFArrayRef identityChain;

    NSOperationQueue *delegateQueue;
    NSURLCredential *credential;
    SecCertificateRef certificate;
}

- (void)connect:(CDVInvokedUrlCommand *)command {
    NSLog(@"[WSC][INFO] Connect was called");

    serverURL = [NSURL URLWithString:@"https://192.168.5.121:8443/rico/index.html"];
//    serverURL = [NSURL URLWithString:@"https://192.168.10.53:8443/rico/index.html"];
    appFolderPath = [[NSBundle mainBundle] resourcePath];
    pkcs12Path = [NSString stringWithFormat:@"%@/%@", appFolderPath, @"www/sma2client2.p12"];
    password = @"aT7kyG";

    NSLog(@"[WSC][INFO] ServerURL:   %@", serverURL);
    NSLog(@"[WSC][INFO] App-Folder:  %@", appFolderPath);
    NSLog(@"[WSC][INFO] P12-File:    %@", pkcs12Path);
    NSLog(@"[WSC][INFO] Password:    %@", password);

    NSURLRequest *request = [NSURLRequest requestWithURL:serverURL];
    if (!request) {
        NSLog(@"[WSC][ERR!] The request is empty!");
        return;
    }

    [self loadPKCS12File];
    [self createCredential];

    NSURLCredentialStorage *credentialStore = [NSURLCredentialStorage sharedCredentialStorage];

    delegateQueue = [[NSOperationQueue alloc] init];
    delegateQueue.maxConcurrentOperationCount = 5;

    // Create Configuration
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    [sessionConfiguration setURLCredentialStorage:credentialStore];

    // Create Session
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:delegateQueue];

    // Create Credential
    SecIdentityCopyCertificate(identityRef, &certificate);
    const void *certs[] = {certificate};
    CFArrayRef certsArray = CFArrayCreate(NULL, certs, 1, NULL);

    CFRelease(certsArray);

    // Create Protection Space
    NSString *host = [request.URL host];
    NSInteger port = [[request.URL port] integerValue];
    NSString *protocol = [request.URL scheme];
    NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:host port:port protocol:protocol realm:nil authenticationMethod:NSURLAuthenticationMethodClientCertificate];

    // Add Credential to Shared Credentials
    [credentialStore setDefaultCredential:credential forProtectionSpace:protectionSpace];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request];
    [dataTask resume];
}

- (void)loadPKCS12File {
    NSLog(@"[WSC][INFO] loadPKCS12File was called");
    NSData *pkcs12data = [NSData dataWithContentsOfFile:pkcs12Path];

    if (!pkcs12data) {
        NSLog(@"[WSC][ ERR] Could not read pkcs#12 file <%@>", pkcs12Path);
        return;
    }

    const void *keys[] = {kSecImportExportPassphrase};
    const void *values[] = {(__bridge const void *) (password)};
    CFDictionaryRef optionsDictionary = NULL;

    optionsDictionary = CFDictionaryCreate(
            NULL, keys,
            values, (password ? 1 : 0),
            NULL, NULL);

    CFArrayRef results;
    OSStatus err = SecPKCS12Import((__bridge CFDataRef) (pkcs12data), optionsDictionary, &results);
    if (err != noErr) {
        NSLog(@"[WSC][ ERR] Could not import pkcs#12 file <%@>", pkcs12Path);
        return;
    }

    if (CFArrayGetCount(results) > 1) {
        NSLog(@"[WSC][ ERR] Too many entreis in the the pkcs#12 file, not smart enough. <%@>", pkcs12Path);
        return;
    }

    CFDictionaryRef result = CFArrayGetValueAtIndex(results, 0);
    identityRef = (SecIdentityRef) CFDictionaryGetValue(result, kSecImportItemIdentity);
    CFRetain(identityRef);

    identityChain = (CFArrayRef) CFDictionaryGetValue(result, kSecImportItemCertChain);

    if (!identityRef) {
        NSLog(@"[WSC][ ERR] No identity in the pkcs#12 file <%@>", pkcs12Path);
        return;
    }
}

- (void)createCredential {
    NSLog(@"[WSC][INFO] createCredential was called");


//    SecPolicyRef policy = SecPolicyCreateBasicX509();
//    const void *certs[] = {certificate};
//    CFArrayRef certArray = CFArrayCreate(kCFAllocatorDefault, certs, 1, NULL);
//
//    OSStatus status;
//    SecTrustRef trust;
//    status = SecTrustCreateWithCertificates(certificate, policy, &trust);
//    status = SecTrustSetAnchorCertificates(trust, certArray);
//    SecTrustResultType trustResult;
//    status = SecTrustEvaluate(trust, &trustResult);

    NSArray *chain = (__bridge NSArray *) identityChain;
    NSArray *slicedChain =@[chain.lastObject];

    credential = [NSURLCredential credentialWithIdentity:identityRef
                                            certificates:slicedChain
                                             persistence:NSURLCredentialPersistenceForSession];

    NSLog(@"[WSC][INFO] createCredential was called successfully");
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    NSLog(@"[WSC][INFO] URLSession.didBecomeInvalidWithError was called");
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *_Nullable credential))completionHandler {
    NSLog(@"[WSC][INFO] URLSession.didReceiveChallenge was called (ProtectionSpace: %@)", challenge.protectionSpace.authenticationMethod);

    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate]) {
        if ([challenge previousFailureCount] == 0) {
            NSLog(@"[WSC][INFO] URLSession.didReceiveChallenge previousFailureCount == 0");
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        } else {
            NSLog(@"[WSC][INFO] URLSession.didReceiveChallenge previousFailureCount != 0");
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        }
    } else {
        NSLog(@"[WSC][INFO] URLSession.didReceiveChallenge Ignoring SSL");
        SecTrustRef trust = challenge.protectionSpace.serverTrust;
        completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:trust]);
    }
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    NSLog(@"[WSC][INFO] URLSession.URLSessionDidFinishEventsForBackgroundURLSession was called");
}


@end