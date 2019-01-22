//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "TSConstants.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const TSRegistrationErrorDomain;
extern NSString *const TSRegistrationErrorUserInfoHTTPStatus;
extern NSString *const RegistrationStateDidChangeNotification;
extern NSString *const DeregistrationStateDidChangeNotification;
extern NSString *const kNSNotificationName_LocalUIDDidChange;

@class AnyPromise;
@class OWSPrimaryStorage;
@class TSNetworkManager;
@class YapDatabaseReadWriteTransaction;
@class RelayRecipient;

@interface TSAccountManager : NSObject

@property (nonatomic, nullable) NSString *uidAwaitingVerification;

#pragma mark - Initializers

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithNetworkManager:(TSNetworkManager *)networkManager
                        primaryStorage:(OWSPrimaryStorage *)primaryStorage NS_DESIGNATED_INITIALIZER;

+ (instancetype)sharedInstance;

@property (nonatomic, strong, readonly) TSNetworkManager *networkManager;

/**
 *  Returns if a user is registered or not
 *
 *  @return registered or not
 */
+ (BOOL)isRegistered;
- (BOOL)isRegistered;

/**
 *  Returns current phone number for this device, which may not yet have been registered.
 *
 *  @return E164 formatted phone number
 */
+ (nullable NSString *)localUID;
- (nullable NSString *)localUID;

/**
 * Returns recipient for self
 */
+(nonnull RelayRecipient *)selfRecipient;
-(nonnull RelayRecipient *)selfRecipient;

/**
 *  Symmetric key that's used to encrypt message payloads from the server,
 *
 *  @return signaling key
 */
+ (nullable NSString *)signalingKey;
- (nullable NSString *)signalingKey;

/**
 *  The server auth token allows the Signal client to connect to the Signal server
 *
 *  @return server authentication token
 */
+ (nullable NSString *)serverAuthToken;
- (nullable NSString *)serverAuthToken;

// Exposing for use by the Forsta device provisioning service
+ (void)storeServerAuthToken:(NSString *)authToken signalingKey:(NSString *)signalingKey;
- (void)storeServerAuthToken:(NSString *)authToken signalingKey:(NSString *)signalingKey;

/**
 *  The registration ID is unique to an installation of TextSecure, it allows to know if the app was reinstalled
 *
 *  @return registrationID;
 */

+ (uint32_t)getOrGenerateRegistrationId;
+ (uint32_t)getOrGenerateRegistrationId:(YapDatabaseReadWriteTransaction *)transaction;

// MARK: Forsta additions
+(nullable NSString *)orgname;
-(nullable NSString *)orgname;

+(nullable NSString *)username;
-(nullable NSString *)username;

+(nullable NSString *)sessiontoken;
-(nullable NSString *)sessiontoken;


#pragma mark - Register with phone number

+ (void)registerWithPhoneNumber:(NSString *)phoneNumber
                        success:(void (^)(void))successBlock
                        failure:(void (^)(NSError *error))failureBlock
                smsVerification:(BOOL)isSMS;

+ (void)rerequestSMSWithSuccess:(void (^)(void))successBlock failure:(void (^)(NSError *error))failureBlock;

+ (void)rerequestVoiceWithSuccess:(void (^)(void))successBlock failure:(void (^)(NSError *error))failureBlock;

- (void)verifyAccountWithCode:(NSString *)verificationCode
                          pin:(nullable NSString *)pin
                      success:(void (^)(void))successBlock
                      failure:(void (^)(NSError *error))failureBlock;

- (void)registerForManualMessageFetchingWithSuccess:(void (^)(void))successBlock
                                            failure:(void (^)(NSError *error))failureBlock;

// Called once registration is complete - meaning the following have succeeded:
// - obtained signal server credentials
// - uploaded pre-keys
// - uploaded push tokens
- (void)finalizeRegistration;

#if TARGET_OS_IPHONE

/**
 *  Register's the device's push notification token with the server
 *
 *  @param pushToken Apple's Push Token
 */
- (void)registerForPushNotificationsWithPushToken:(NSString *)pushToken
                                        voipToken:(NSString *)voipToken
                                          success:(void (^)(void))successHandler
                                          failure:(void (^)(NSError *error))failureHandler
    NS_SWIFT_NAME(registerForPushNotifications(pushToken:voipToken:success:failure:));

#endif

+ (void)unregisterTextSecureWithSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failureBlock;

#pragma mark - De-Registration

// De-registration reflects whether or not the "last known contact"
// with the service was:
//
// * A 403 from the service, indicating de-registration.
// * A successful auth'd request _or_ websocket connection indicating
//   valid registration.
- (BOOL)isDeregistered;
- (void)setIsDeregistered:(BOOL)isDeregistered;

#pragma mark - Re-registration

// Re-registration is the process of re-registering _with the same phone number_.

// Returns YES on success.
- (BOOL)resetForReregistration;
- (NSString *)reregisterationPhoneNumber;
- (BOOL)isReregistering;

#pragma mark - Manual Message Fetch

- (BOOL)isManualMessageFetchEnabled;
- (AnyPromise *)setIsManualMessageFetchEnabled:(BOOL)value __attribute__((warn_unused_result));

@end

NS_ASSUME_NONNULL_END
