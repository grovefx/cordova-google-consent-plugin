#import <Cordova/CDVPlugin.h>

@interface CordovaGoogleConsentPlugin : CDVPlugin {
}

- (void)setDebugOptions : (CDVInvokedUrlCommand *)command;
- (void)requestConsentStatus : (CDVInvokedUrlCommand *)command;
- (void)loadConsentForm : (CDVInvokedUrlCommand *)command;

@end
