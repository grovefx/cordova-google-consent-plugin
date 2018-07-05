#import <Cordova/CDVPlugin.h>

@interface MyCordovaPlugin : CDVPlugin {
}

- (void)echo : (CDVInvokedUrlCommand *)command;
- (void)setDebugOptions : (CDVInvokedUrlCommand *)command;
- (void)requestConsentStatus : (CDVInvokedUrlCommand *)command;
- (void)loadConsentForm : (CDVInvokedUrlCommand *)command;

@end
