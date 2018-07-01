
var exec = require('cordova/exec');

var PLUGIN_NAME = 'CordovaGoogleConsentPlugin';

var CordovaGoogleConsentPlugin = {
  setDebugOptions: function(debugOptions, successCallback, failureCallback) {
    exec(successCallback, failureCallback, PLUGIN_NAME, 'setDebugOptions', [debugOptions]);
  },
  requestConsentStatus: function(publisherIdsArray, successCallback, failureCallback) {
    exec(successCallback, failureCallback, PLUGIN_NAME, 'requestConsentStatus', [publisherIdsArray]);
  },
  loadConsentForm: function(privacyUrl, successCallback, failureCallback) {
    exec(successCallback, failureCallback, PLUGIN_NAME, 'loadConsentForm', [privacyUrl]);
  }
};


module.exports = CordovaGoogleConsentPlugin;
