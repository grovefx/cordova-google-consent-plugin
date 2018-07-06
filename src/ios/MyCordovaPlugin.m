#import "MyCordovaPlugin.h"
#import <Cordova/CDVAvailability.h>
#import <PersonalizedAdConsent/PersonalizedAdConsent.h>

@implementation MyCordovaPlugin

- (void)pluginInitialize {
}

- (void)setDebugOptions:(CDVInvokedUrlCommand*)command
{
    NSObject* debugOptionsObject = [command.arguments objectAtIndex:0];
    NSString* geo = [debugOptionsObject valueForKey:@"geogrpaphy"];

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
//    NSArray *pubIdArray = @[pubId];
//    NSArray* pubIdArray = [NSArray arrayWithObjects: pubId, nil];
    [PACConsentInformation.sharedInstance
     requestConsentInfoUpdateForPublisherIdentifiers:pubId
     completionHandler:^(NSError *_Nullable error) {

         if (error) {
             NSLog(@"requestConsentStatus - Error: %@", error);
             CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
             [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
         } else {
             NSString* resultString;
             if ( PACConsentInformation.sharedInstance.consentStatus == PACConsentStatusPersonalized ) {
                 resultString = @"PERSONALIZED";
             } else if ( PACConsentInformation.sharedInstance.consentStatus == PACConsentStatusNonPersonalized ) {
                 resultString = @"NON_PERSONALIZED";
//             } else if ( PACConsentInformation.sharedInstance.consentStatus == PACConsentStatusUnknown ) {
             } else {
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
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        } else {
            [form presentFromViewController:self.viewController dismissCompletion:^(NSError *_Nullable error, BOOL userPrefersAdFree) {
                  if (error) {
                      CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
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
