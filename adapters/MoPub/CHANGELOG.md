# MoPub Ads Mediation Adapter for Google Mobile Ads SDK for iOS

## Version 4.18.0.0
- Verified compatibility with MoPub SDK 4.18.0.

## Version 4.17.0.0
- Updated the deployment target to iOS 8.
- Updated the adapter to make it compatibe with MoPub SDK 4.17.0.

## Version 4.16.0.0
- The adapter now depends on `mopub-ios-sdk/Core`. MoPub SDK uses Integral Ad
  Science, Inc. (“IAS”) and Moat, Inc for reporting and viewability measurement.
  If you wish to use these libaries, they need to be added to your app
  separately. See [Disabling Viewability Measurement](https://github.com/mopub/mopub-ios-sdk#disabling-viewability-measurement)
  for more details on how to add these libraries separately.
- Verified compatibility with MoPub SDK 4.16.0.

## Version 4.15.0.0
- Verified compatibility with MoPub SDK 4.15.0.

## Version 4.14.0.0
- Verified compatibility with MoPub SDK 4.14.0.
- Removed the support for `armv7s` architecture.
- Fixed a bug where Native Ads failed to load MoPub privacy icon when MoPub SDK
  is linked using CocoaPods and having `use_frameworks!` in the Podfile for
  Swift projects.

## Version 4.13.1.1
- Fixed a bug where native ads failed to detect clicks when loaded from the same
  `GADAdLoader` instance.

## Version 4.13.1.0
- Verified compatibility with MoPub SDK 4.13.1.

## Version 4.13.0.0
- Verified compatibility with MoPub SDK 4.13.0.

## Version 4.12.0.0
- Verified compatibility with MoPub SDK 4.12.0.
- Added support for accessing MoPub native demand on Google Mobile Ads
  mediation.
- Added support to configure the privacy icon size for MoPub's native ads.
- Updated banner and interstitial ad formats per Google Mobile Ads latest
  mediation APIs.
- Adapter is now distributed as a framework.

## Previous Versions
- Support for MoPub banner and interstitial ads.
