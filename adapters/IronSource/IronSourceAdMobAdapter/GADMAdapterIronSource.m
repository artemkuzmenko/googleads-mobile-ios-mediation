// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMAdapterIronSource.h"

// IronSource mediation network adapter version.
NSString *const kGADMAdapterIronSourceVersion = @"6.7.3.0";
// IronSource internal reporting const
NSString *const kGADMMediationName = @"AdMob";
// IronSource parameters keys
NSString *const kGADMAdapterIronSourceAppKey = @"appKey";
NSString *const kGADMAdapterIronSourceIsTestEnabled = @"isTestEnabled";
NSString *const kGADMAdapterIronSourceRewardedVideoPlacement = @"rewardedVideoPlacement";
NSString *const kGADMAdapterIronSourceInterstitialPlacement = @"interstitialPlacement";

@interface GADMAdapterIronSource () {
    //Connector from Google Mobile Ads SDK to receive rewarded video ad configurations.
    __weak id<GADMRewardBasedVideoAdNetworkConnector> _rewardbasedVideoAdConnector;
    
    //Yes if we want to show adapter logs
    BOOL _isTestEnabled;
    
    //IronSource rewarded video placement name
    NSString* _interstitialPlacementName;
    
    //IronSource interstitial placement name
    NSString* _rewardedVideoPlacementName;
}

@end

@implementation GADMAdapterIronSource

// Will be set by the SDK.
@synthesize delegate = delegate_;

#pragma mark Admob GADMRewardBasedVideoAdNetworkAdapter

+ (NSString *)adapterVersion {
    return kGADMAdapterIronSourceVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
    return [GADMIronSourceExtras class];
}

- (instancetype)initWithRewardBasedVideoAdNetworkConnector: (id<GADMRewardBasedVideoAdNetworkConnector>)connector {
    if (!connector) {
        return nil;
    }
    self = [super init];
    if (self) {
        _rewardbasedVideoAdConnector = connector;
    }
    return self;
}

- (void)setUp {
    id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
    
    NSString* applicationKey = @"";
    if ([[strongConnector credentials] objectForKey:kGADMAdapterIronSourceAppKey]) {
        applicationKey = [[strongConnector credentials] objectForKey:kGADMAdapterIronSourceAppKey];
    }
    
    if ([[strongConnector credentials] objectForKey:kGADMAdapterIronSourceIsTestEnabled] != nil) {
        _isTestEnabled = [[[strongConnector credentials] objectForKey:kGADMAdapterIronSourceIsTestEnabled] boolValue];
    } else {
        _isTestEnabled = NO;
    }
    
    if ([[strongConnector credentials] objectForKey:@"placementName"] != nil){
        _rewardedVideoPlacementName = [[strongConnector credentials] objectForKey:@"placementName"];
    } else {
        _rewardedVideoPlacementName = nil;
    }
    
    [self onLog:[NSString stringWithFormat:@"setUp params: appKey=%@, _isTestEnabled=%d, _rewardedVideoPlacementName=%@, _interstitialPlacementName=%@", applicationKey, _isTestEnabled, _rewardedVideoPlacementName, _interstitialPlacementName]];
    
    if (applicationKey && applicationKey.length > 0) {
        [IronSource setRewardedVideoDelegate:self];
        [self initIronSourceSDKWithAppKey:applicationKey adUnit:IS_REWARDED_VIDEO];
        [self requestRewardBasedVideoAd];
    } else {
        NSError* error = [self createErrorWith:@"IronSource Adapter failed to setUp" andReason:@"appKey parameter is missing" andSuggestion:@"make sure that 'appKey' server parameter is added"];
        [strongConnector adapter:self didFailToSetUpRewardBasedVideoAdWithError:error];
    }
    
    [self onLog:@"setUp"];
}

- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController {
    [self onLog:@"presentRewardBasedVideoAdWithRootViewController"];
    
    if ([self isEmpty:_rewardedVideoPlacementName]) {
        [IronSource showRewardedVideoWithViewController:viewController];
    } else {
        [IronSource showRewardedVideoWithViewController:viewController placement:_rewardedVideoPlacementName];
    }
}

- (void)stopBeingDelegate {
    [self onLog:@"stopBeingDelegate"];
}

- (void)getBannerWithSize:(GADAdSize)adSize {
    [self showBannersNotSupportedError];
}

- (void)requestInterstitialAdWithParameter:(NSString *)serverParameter
                                     label:(NSString *)serverLabel
                                   request:(GADCustomEventRequest *)request {
    
    NSData *jsonData = [serverParameter dataUsingEncoding:NSUTF8StringEncoding];
    NSError *parseJsonError;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&parseJsonError];
    
    NSString* applicationKey = @"";
    
    if (parseJsonError == nil) {
        
        if ([dict objectForKey:kGADMAdapterIronSourceAppKey] != nil){
            applicationKey = [dict objectForKey:kGADMAdapterIronSourceAppKey];
        }
        
        if ([dict objectForKey:@"applicationKey"] != nil){
            applicationKey = [dict objectForKey:@"applicationKey"];
        }
        
        if ([dict objectForKey:kGADMAdapterIronSourceIsTestEnabled] != nil){
            _isTestEnabled = [[dict objectForKey:kGADMAdapterIronSourceIsTestEnabled] boolValue];
        } else {
            _isTestEnabled = NO;
        }
        
        if ([dict objectForKey:@"placementName"] != nil){
            _interstitialPlacementName = [dict objectForKey:@"placementName"];
        } else {
            _interstitialPlacementName = nil;
        }
    }
    
    [self onLog:[NSString stringWithFormat:@"server params: %@", dict.description]];
    
    if (applicationKey && applicationKey.length > 0) {
        [IronSource setInterstitialDelegate:self];
        
        [self initIronSourceSDKWithAppKey:applicationKey adUnit:IS_INTERSTITIAL];
        [self loadInterstitialAd];
        
    } else {
        NSError* appKeyError = [self createErrorWith:@"Missed application key in admob server parameter" andReason:@"You forget to add applicationKey param in the admob parameter." andSuggestion:@"Please check ironSource documentation, ther server parameter should be with a applicationKey."];
        [self.delegate customEventInterstitial:self didFailAd:appKeyError];
    }
}

- (void)presentFromRootViewController:(UIViewController *)rootViewController {
    [self onLog:@"presentFromRootViewController"];
    
    if (_interstitialPlacementName) {
        [IronSource showInterstitialWithViewController:rootViewController placement:_interstitialPlacementName];
    } else {
        [IronSource showInterstitialWithViewController:rootViewController];
    }
}

#pragma mark Utils Methods

-(void) initIronSourceSDKWithAppKey:(NSString*)appKey adUnit:(NSString*)adUnit {
    // 1 - We are not sending user ID from adapters anymore,
    //     the IronSource SDK will take care of this identifier
    
    // 2 - We assume the init is always successful (we will fail in load if needed)
    
    [ISConfigurations getConfigurations].plugin = kGADMMediationName;
    [ISConfigurations getConfigurations].pluginVersion = kGADMAdapterIronSourceVersion;
    
    NSString* admobVersion = [[NSString alloc] initWithBytes:GoogleMobileAdsVersionString
                                                      length:strlen((char*)GoogleMobileAdsVersionString) encoding:NSASCIIStringEncoding];
    
    [ISConfigurations getConfigurations].pluginFrameworkVersion = admobVersion;
    
    [IronSource initWithAppKey:appKey adUnits:@[adUnit]];
    
    [self onLog:@"initIronSourceSDKWithAppKey"];
    
    if ([adUnit isEqualToString:IS_REWARDED_VIDEO]) {
        id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
        [strongConnector adapterDidSetUpRewardBasedVideoAd:self];
    } else if ([adUnit isEqualToString:IS_INTERSTITIAL]) {
        
    }
}

- (void)requestRewardBasedVideoAd {
    [self onLog:@"requestRewardBasedVideoAd"];
    if([IronSource hasRewardedVideo]) {
        [self onLog:@"reward based video ad is available"];
        id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
        [strongConnector adapterDidReceiveRewardBasedVideoAd:self];
    }
}

- (void)loadInterstitialAd {
    [self onLog:@"loadInterstitialAd"];
    
    if ([IronSource hasInterstitial]) {
        [self.delegate customEventInterstitialDidReceiveAd:self];
    } else {
        [IronSource loadInterstitial];
    }
}

- (void) onLog: (NSString *) log {
    if(_isTestEnabled) {
        NSLog(@"IronSourceAdapter: %@" , log);
    }
}

-(BOOL) isEmpty: (id) thing
{
    return thing == nil
    || [thing isKindOfClass:[NSNull class]]
    || ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
    || ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
    
}

- (NSError*) createErrorWith:(NSString*)description andReason:(NSString*)reason andSuggestion:(NSString*)suggestion {
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: NSLocalizedString(description, nil),
                               NSLocalizedFailureReasonErrorKey: NSLocalizedString(reason, nil),
                               NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(suggestion, nil)
                               };
    
    return [NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:userInfo];
}

- (void)showBannersNotSupportedError {
    // IronSource Adapter doesn't support banner ads.
    NSError* error = [self createErrorWith:@"IronSource Adapter doesn't support banner ads" andReason:@"" andSuggestion:@""];
    [self.delegate customEventInterstitial:self didFailAd:error];
}

#pragma mark IronSource Rewarded Video Delegate implementation

/*!
 * @discussion Invoked when there is a change in the ad availability status.
 *
 *              hasAvailableAds - value will change to YES when rewarded videos are available.
 *              You can then show the video by calling showRV(). Value will change to NO when no videos are available.
 */
- (void)rewardedVideoHasChangedAvailability:(BOOL)available {
    [self onLog: [NSString stringWithFormat:@"%@ - %i" , @"rewardedVideoHasChangedAvailability: " , available]];
    
    id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
    if (available) {
        [strongConnector adapterDidReceiveRewardBasedVideoAd:self];
    } else {
        NSError* AvailableAdsError = [self createErrorWith:@"IronSource network isn't available" andReason:@"Network fill issue" andSuggestion:@"Please talk with your PM and check that your network configuration are according to the documentation."];
        [strongConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:AvailableAdsError];
    }
}

/*!
 * @discussion Invoked when the user completed the video and should be rewarded.
 *
 *              If using server-to-server callbacks you may ignore these events and wait for the callback from the IronSource server.
 *              placementInfo - IronSourcePlacementInfo - an object contains the placement's reward name and amount
 */
- (void)didReceiveRewardForPlacement:(ISPlacementInfo *)placementInfo {
    [self onLog:@"didReceiveRewardForPlacement"];
    
    GADAdReward *reward;
    if (placementInfo) {
        NSString * rewardName = [placementInfo rewardName];
        NSNumber * rewardAmount = [placementInfo rewardAmount];
        reward = [[GADAdReward alloc] initWithRewardType:rewardName
                                            rewardAmount:[NSDecimalNumber decimalNumberWithDecimal:[rewardAmount decimalValue]]];
        
        id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
        [strongConnector adapter: self didRewardUserWithReward:reward];
        
    } else {
        [self onLog:@"ironSourceRVAdRewarded - did not receive placement info"];
    }
}

/*!
 * @discussion Invoked when an Ad failed to display.
 *
 *          error - NSError which contains the reason for the failure.
 *          The error contains error.code and error.message.
 */
- (void)rewardedVideoDidFailToShowWithError:(NSError *)error {
    [self onLog:@"rewardedVideoDidFailToShowWithError:"];
}

/*!
 * @discussion Invoked when the RewardedVideo ad view has opened.
 *
 */
- (void)rewardedVideoDidOpen {
    [self onLog:@"rewardedVideoDidOpen"];
    
    id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
    [strongConnector adapterDidOpenRewardBasedVideoAd:self];
    [strongConnector adapterDidStartPlayingRewardBasedVideoAd:self];
}

/*!
 * @discussion Invoked when the user is about to return to the application after closing the RewardedVideo ad.
 *
 */
- (void)rewardedVideoDidClose {
    [self onLog:@"rewardedVideoDidClose"];
    
    id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
    [strongConnector adapterDidCloseRewardBasedVideoAd:self];
}

/*!
 * @discussion Invoked when the video ad starts playing.
 *
 *             Available for: AdColony, Vungle, AppLovin, UnityAds
 */
- (void)rewardedVideoDidStart {
    [self onLog:@"rewardedVideoDidStart"];
}

/*!
 * @discussion Invoked when the video ad finishes playing.
 *
 *             Available for: AdColony, Flurry, Vungle, AppLovin, UnityAds.
 */
- (void)rewardedVideoDidEnd {
    [self onLog:@"rewardedVideoDidEnd"];
}

- (void)didClickRewardedVideo:(ISPlacementInfo *)placementInfo {
    [self onLog:@"didClickRewardedVideo"];
    
    id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
    [strongConnector adapterDidGetAdClick:self];
    [strongConnector adapterWillLeaveApplication:self];
}

#pragma mark IronSource Interstitial Delegates implementation

- (void)interstitialDidLoad {
    [self onLog:@"interstitialDidLoad"];
    
    [self.delegate customEventInterstitialDidReceiveAd:self];
}

- (void)interstitialDidFailToLoadWithError:(NSError *)error {
    [self onLog:[NSString stringWithFormat:@"interstitialDidFailToLoadWithError: %@", error.localizedDescription]];
    
    if (!error) {
        error = [self createErrorWith:@"netowrk load error"
                            andReason:@"IronSource network failed to load"
                        andSuggestion:@"Please talk with your PM and check that your network configuration are according to the documentation."];
    }
    
    [self.delegate customEventInterstitial:self didFailAd:error];
}

/*!
 * @discussion Called each time the Interstitial window is about to open
 */
- (void)interstitialDidOpen {
    [self onLog:@"interstitialDidOpen"];
    
    [self.delegate customEventInterstitialWillPresent:self];
}

/*!
 * @discussion Called each time the Interstitial window is about to close
 */
- (void)interstitialDidClose {
    [self onLog:@"interstitialDidClose"];
    
    id<GADCustomEventInterstitialDelegate> strongDelegate = self.delegate;
    [strongDelegate customEventInterstitialWillDismiss:self];
    [strongDelegate customEventInterstitialDidDismiss:self];
}

/*!
 * @discussion Called each time the Interstitial window has opened successfully.
 */
- (void)interstitialDidShow {
    [self onLog:@"interstitialDidShow"];
}

/*!
 * @discussion Called if showing the Interstitial for the user has failed.
 *
 *              You can learn about the reason by examining the ‘error’ value
 */
- (void)interstitialDidFailToShowWithError:(NSError *)error {
    [self onLog:@"interstitialDidFailToShowWithError:"];
    
    [self.delegate customEventInterstitial:self didFailAd:error];
}

/*!
 * @discussion Called each time the end user has clicked on the Interstitial ad.
 */
- (void)didClickInterstitial{
    [self onLog:@"didClickInterstitial"];
    
    id<GADCustomEventInterstitialDelegate> strongDelegate = self.delegate;
    [strongDelegate customEventInterstitialWasClicked:self];
    [strongDelegate customEventInterstitialWillLeaveApplication:self]; //discussed with PM - always send this event in click (interstitial)
}

@end
