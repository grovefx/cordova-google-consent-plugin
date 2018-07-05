#import "MyCordovaPlugin.h"

#import <Cordova/CDVAvailability.h>
#import <PersonalizedAdConsent/PersonalizedAdConsent.h>

@implementation MyCordovaPlugin

- (void)pluginInitialize {
}

- (void)echo:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = [command callbackId];
    NSString* msg = [NSString stringWithFormat: @"Echo: %@", [[command arguments] objectAtIndex:0]];

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:msg];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)setDebugOptions:(CDVInvokedUrlCommand*)command
{
    NSObject* debugOptionsObject = [command.arguments objectAtIndex:0];
    NSString* geo = [debugOptionsObject valueForKey:@"geogrpaphy"];
    NSLog(@"%@", geo);

//    PACConsentInformation.sharedInstance.debugIdentifiers = @[ @"41E538F6-9C98-4EF2-B3EE-D7BD8CAF8339" ];
    if (geo != (id)[NSNull null] ) {
        if ([geo isEqualToString:@"EEA"]) {
            PACConsentInformation.sharedInstance.debugGeography = PACDebugGeographyEEA;
        } else if ([geo isEqualToString:@"NOT_EEA"]) {
            PACConsentInformation.sharedInstance.debugGeography = PACDebugGeographyNotEEA;
        } else if ([geo isEqualToString:@"DISABLED"]) {
            PACConsentInformation.sharedInstance.debugGeography = PACDebugGeographyDisabled;
        }
    }
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)requestConsentStatus:(CDVInvokedUrlCommand*)command
{
    NSString* pubId = [command.arguments objectAtIndex:0];

    NSLog(@"DIMA");
    NSLog(@"%@", pubId);
    [PACConsentInformation.sharedInstance
     requestConsentInfoUpdateForPublisherIdentifiers:pubId
     completionHandler:^(NSError *_Nullable error) {

         if (error) {
             NSLog(@"DIMA1");
             NSLog(@"%@", error);
             // Consent info update failed.
         } else {
             NSLog(@"DIMA2");
             NSLog(@"%li", PACConsentInformation.sharedInstance.consentStatus);

             NSString* resultString;
             if ( PACConsentInformation.sharedInstance.consentStatus == PACConsentStatusPersonalized ) {
                 resultString = @"PERSONALIZED";
             } else if ( PACConsentInformation.sharedInstance.consentStatus == PACConsentStatusNonPersonalized ) {
                 resultString = @"NON_PERSONALIZED";
             } else if ( PACConsentInformation.sharedInstance.consentStatus == PACConsentStatusUnknown ) {
                 resultString = @"UNKNOWN";
             }
             CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:resultString];
             [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
         }
     }];

}

- (void)loadConsentForm:(CDVInvokedUrlCommand*)command
{
    NSString* privacyUrl = [command.arguments objectAtIndex:0];
    NSURL *privacyURL = [NSURL URLWithString:privacyUrl];
    PACConsentForm *form = [[PACConsentForm alloc] initWithApplicationPrivacyPolicyURL:privacyURL];
    form.shouldOfferPersonalizedAds = YES;
    form.shouldOfferNonPersonalizedAds = YES;
    form.shouldOfferAdFree = NO;

    [form loadWithCompletionHandler:^(NSError *_Nullable error) {
        if (error) {
            NSLog(@"Load complete. Error: %@", error);
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        } else {
            [form presentFromViewController:self.viewController dismissCompletion:^(NSError *_Nullable error, BOOL userPrefersAdFree) {
                  if (error) {
                      CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error];
                      [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                  } else if (userPrefersAdFree) {
                      NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:@"true", @"userPrefersAdFree", nil];
                      CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dict];
                      [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                  } else {
                      NSString* status;
                      if ( PACConsentInformation.sharedInstance.consentStatus == PACConsentStatusPersonalized ) {
                          status = @"PERSONALIZED";
                      } else if ( PACConsentInformation.sharedInstance.consentStatus == PACConsentStatusNonPersonalized ) {
                          status = @"NON_PERSONALIZED";
                      } else if ( PACConsentInformation.sharedInstance.consentStatus == PACConsentStatusUnknown ) {
                          status = @"UNKNOWN";
                      }
                      NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:status, @"consentStatus", nil];
                      CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dict];
                      [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                  }
              }];
        }
    }];
}


@end
