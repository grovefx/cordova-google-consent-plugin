package com.grovefx.plugins;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.google.ads.consent.ConsentForm;
import com.google.ads.consent.ConsentFormListener;
import com.google.ads.consent.ConsentInfoUpdateListener;
import com.google.ads.consent.ConsentInformation;
import com.google.ads.consent.ConsentStatus;
import com.google.ads.consent.DebugGeography;

import android.util.Log;

import java.net.MalformedURLException;
import java.net.URL;

public class GoogleConsent extends CordovaPlugin {
  private static final String TAG = "[CordovaGoogleConsent]";

  private ConsentInformation mConsentInformation;
  private ConsentForm mConsentForm;

  public void initialize(CordovaInterface cordova, CordovaWebView webView) {
    super.initialize(cordova, webView);
    Log.d(TAG, "Initializing");
    this.mConsentInformation = ConsentInformation.getInstance(webView.getContext());
  }

  public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) {
    if (action.equals("setDebugOptions")) {
      setDebugOptions(args, callbackContext);
    } else if (action.equals("requestConsentStatus")) {
      requestConsentStatus(args, callbackContext);
    } else if (action.equals("loadConsentForm")) {
      loadConsentForm(args, callbackContext);
    } else {
      callbackContext.error("unknown action");
    }
    return true;
  }

  private void setDebugOptions(JSONArray args, CallbackContext callbackContext) {
    String geographyDebugOption = null;
    String[] testDevices = null;

    try {
      JSONObject debugOptionsObject = args.getJSONObject(0);

      if (debugOptionsObject.has("geogrpaphy")) {
        geographyDebugOption = debugOptionsObject.getString("geogrpaphy");
      }
      if (debugOptionsObject.has("testDevices")) {
        JSONArray testDevicesJsonArray = debugOptionsObject.getJSONArray("testDevices");
        testDevices = new String[testDevicesJsonArray.length()];
        for (int i = 0; i < testDevicesJsonArray.length(); i++) {
          testDevices[i] = testDevicesJsonArray.getString(i);
        }
      }

    } catch (JSONException e) {
      callbackContext.error("unable to parse params");
      return;
    }

    if ("EEA".equalsIgnoreCase(geographyDebugOption)) {
      mConsentInformation.setDebugGeography(DebugGeography.DEBUG_GEOGRAPHY_EEA);
      Log.i(TAG, "set DEBUG_GEOGRAPHY_EEA");
    } else if ("NOT_EEA".equalsIgnoreCase(geographyDebugOption)) {
      mConsentInformation.setDebugGeography(DebugGeography.DEBUG_GEOGRAPHY_NOT_EEA);
      Log.i(TAG, "set DEBUG_GEOGRAPHY_NOT_EEA");
    } else if ("DISABLED".equalsIgnoreCase(geographyDebugOption)) {
      mConsentInformation.setDebugGeography(DebugGeography.DEBUG_GEOGRAPHY_DISABLED);
      Log.i(TAG, "set DEBUG_GEOGRAPHY_DISABLED");
    }
    if (testDevices != null && testDevices.length > 0) {
      Log.i(TAG, "adding test device:");
      for (String deviceHash : testDevices) {
        mConsentInformation.addTestDevice(deviceHash);
        Log.i(TAG, deviceHash);

      }
    }
    callbackContext.success("done");
  }

  private void requestConsentStatus(JSONArray args, final CallbackContext callbackContext) {
    String[] publisherIds;
    try {
      JSONArray publisherIdsArray = args.getJSONArray(0);
      if (publisherIdsArray.length() == 0) {
        throw new Exception();
      }
      publisherIds = new String[publisherIdsArray.length()];
      for (int i = 0; i < publisherIdsArray.length(); i++) {
        publisherIds[i] = publisherIdsArray.getString(i);
      }

    } catch (Exception e) {
      callbackContext.error("unable to parse params");
      return;
    }

    mConsentInformation.requestConsentInfoUpdate(publisherIds, new ConsentInfoUpdateListener() {
      @Override
      public void onConsentInfoUpdated(ConsentStatus consentStatus) {
        callbackContext.success(consentStatus != null ? consentStatus.name() : null);
      }

      @Override
      public void onFailedToUpdateConsentInfo(String errorDescription) {
        callbackContext.error(errorDescription);
      }
    });
  }

  protected void loadConsentForm(JSONArray args, final CallbackContext callbackContext) {
    String privacyUrlString;
    try {
      privacyUrlString = args.getString(0);
    } catch (JSONException e) {
      callbackContext.error("unable to get privacy url");
      return;
    }

    final URL privacyUrl;
    try {
      privacyUrl = new URL(privacyUrlString);
    } catch (MalformedURLException e) {
      callbackContext.error("invalid privacy url");
      return;
    }

    cordova.getActivity().runOnUiThread(new Runnable() {
      @Override
      public void run() {

      GoogleConsent.this.mConsentForm = new ConsentForm.Builder(webView.getContext(), privacyUrl)
              .withListener(new ConsentFormListener() {
                @Override
                public void onConsentFormLoaded() {
                  GoogleConsent.this.mConsentForm.show();
                  Log.i(TAG, "consent form is loaded");
                }

                @Override
                public void onConsentFormOpened() {
                  Log.i(TAG, "consent form is opened");
                }

                @Override
                public void onConsentFormClosed(ConsentStatus consentStatus, Boolean userPrefersAdFree) {
                  Log.i(TAG, "consent form is closed");
                  JSONObject result = new JSONObject();
                  try {
                    result.put("consentStatus", consentStatus != null ? consentStatus.name(): null);
                    if (userPrefersAdFree != null) {
                      result.put("userPrefersAdFree", userPrefersAdFree);
                    }
                  } catch (JSONException e) {
                    callbackContext.error("unknown error: " + e.getMessage());
                    return;
                  }
                  callbackContext.success();
                }

                @Override
                public void onConsentFormError(String errorDescription) {
                  Log.i(TAG, "consent form error");

                }
              })
              .withPersonalizedAdsOption()
              .withNonPersonalizedAdsOption()
              .build();
        GoogleConsent.this.mConsentForm.load();
      }
    });
  }
}
