//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "NotificationsManager.h"
#import "PushManager.h"
#import "Relay-Swift.h"

@import AudioToolbox;
@import RelayServiceKit;
@import YapDatabase;
@import Pods_RelayMessaging;

@interface NotificationsManager ()

@property (nonatomic, readonly) NSMutableDictionary<NSString *, UILocalNotification *> *currentNotifications;
@property (nonatomic, readonly) NotificationType notificationPreviewType;

@property (nonatomic, readonly) NSMutableArray<NSDate *> *notificationHistory;
@property (nonatomic, nullable) OWSAudioPlayer *audioPlayer;

@end

#pragma mark -

@implementation NotificationsManager

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return self;
    }

    _currentNotifications = [NSMutableDictionary new];

    _notificationHistory = [NSMutableArray new];

    OWSSingletonAssert();

    return self;
}

#pragma mark - Signal Calls

/**
 * Notify user for incoming WebRTC Call
 */
- (void)presentIncomingCall:(RelayCall *)call callerName:(NSString *)callerName
{
    /*
    DDLogDebug(@"%@ incoming call from: %@", self.logTag, call.callId);

    UILocalNotification *notification = [UILocalNotification new];
    notification.category = PushManagerCategoriesIncomingCall;
    // Rather than using notification sounds, we control the ringtone and repeat vibrations with the CallAudioManager.
    notification.soundName = [OWSSounds filenameForSound:OWSSound_DefaultiOSIncomingRingtone];
    NSString *localCallId = call.localId.UUIDString;
    notification.userInfo = @{ PushManagerUserInfoKeysLocalCallId : localCallId };

    NSString *alertMessage;
    switch (self.notificationPreviewType) {
        case NotificationNoNameNoPreview: {
            alertMessage = NSLocalizedString(@"INCOMING_CALL", @"notification body");
            break;
        }
        case NotificationNameNoPreview:
        case NotificationNamePreview: {
            alertMessage =
                [NSString stringWithFormat:NSLocalizedString(@"INCOMING_CALL_FROM", @"notification body"), callerName];
            break;
        }
    }
    notification.alertBody = [NSString stringWithFormat:@"☎️ %@", alertMessage];

    [self presentNotification:notification identifier:localCallId];
     */
}

/**
 * Notify user for missed WebRTC Call
 */
- (void)presentMissedCall:(RelayCall *)call callerName:(NSString *)callerName
{
    /*
    TSThread *thread = [TSThread getOrCreateThreadWithId:call.callId];
    OWSAssert(thread != nil);

    UILocalNotification *notification = [UILocalNotification new];
    notification.category = PushManagerCategoriesMissedCall;
    NSString *localCallId = call.localId.UUIDString;
    notification.userInfo = @{
        PushManagerUserInfoKeysLocalCallId : localCallId,
        PushManagerUserInfoKeysCallBackSignalRecipientId : call.callId,
        Signal_Thread_UserInfo_Key : thread.uniqueId
    };

    if ([self shouldPlaySoundForNotification]) {
        OWSSound sound = [OWSSounds notificationSoundForThread:thread];
        notification.soundName = [OWSSounds filenameForSound:sound];
    }

    NSString *alertMessage;
    switch (self.notificationPreviewType) {
        case NotificationNoNameNoPreview: {
            alertMessage = [CallStrings missedCallNotificationBodyWithoutCallerName];
            break;
        }
        case NotificationNameNoPreview:
        case NotificationNamePreview: {
            alertMessage =
                [NSString stringWithFormat:[CallStrings missedCallNotificationBodyWithCallerName], callerName];
            break;
        }
    }
    notification.alertBody = [NSString stringWithFormat:@"☎️ %@", alertMessage];

    [self presentNotification:notification identifier:localCallId];
     */
}


- (void)presentMissedCallBecauseOfNewIdentity:(RelayCall *)call callerName:(NSString *)callerName
{
    /*
    TSThread *thread = [TSThread getOrCreateThreadWithId:call.callId];
    OWSAssert(thread != nil);

    UILocalNotification *notification = [UILocalNotification new];
    // Use category which allows call back
    notification.category = PushManagerCategoriesMissedCall;
    NSString *localCallId = call.localId.UUIDString;
    notification.userInfo = @{
        PushManagerUserInfoKeysLocalCallId : localCallId,
        PushManagerUserInfoKeysCallBackSignalRecipientId : call.callId,
        Signal_Thread_UserInfo_Key : thread.uniqueId
    };
    if ([self shouldPlaySoundForNotification]) {
        OWSSound sound = [OWSSounds notificationSoundForThread:thread];
        notification.soundName = [OWSSounds filenameForSound:sound];
    }

    NSString *alertMessage;
    switch (self.notificationPreviewType) {
        case NotificationNoNameNoPreview: {
            alertMessage = [CallStrings missedCallWithIdentityChangeNotificationBodyWithoutCallerName];
            break;
        }
        case NotificationNameNoPreview:
        case NotificationNamePreview: {
            alertMessage = [NSString
                stringWithFormat:[CallStrings missedCallWithIdentityChangeNotificationBodyWithCallerName], callerName];
            break;
        }
    }
    notification.alertBody = [NSString stringWithFormat:@"☎️ %@", alertMessage];

    [self presentNotification:notification identifier:localCallId];
     */
}

- (void)presentMissedCallBecauseOfNoLongerVerifiedIdentity:(RelayCall *)call callerName:(NSString *)callerName
{
    /*
    TSThread *thread = [TSThread getOrCreateThreadWithId:call.callId];
    OWSAssert(thread != nil);

    UILocalNotification *notification = [UILocalNotification new];
    // Use category which does not allow call back
    notification.category = PushManagerCategoriesMissedCallFromNoLongerVerifiedIdentity;
    NSString *localCallId = call.localId.UUIDString;
    notification.userInfo = @{
        PushManagerUserInfoKeysLocalCallId : localCallId,
        PushManagerUserInfoKeysCallBackSignalRecipientId : call.callId,
        Signal_Thread_UserInfo_Key : thread.uniqueId
    };
    if ([self shouldPlaySoundForNotification]) {
        OWSSound sound = [OWSSounds notificationSoundForThread:thread];
        notification.soundName = [OWSSounds filenameForSound:sound];
    }

    NSString *alertMessage;
    switch (self.notificationPreviewType) {
        case NotificationNoNameNoPreview: {
            alertMessage = [CallStrings missedCallWithIdentityChangeNotificationBodyWithoutCallerName];
            break;
        }
        case NotificationNameNoPreview:
        case NotificationNamePreview: {
            alertMessage = [NSString
                stringWithFormat:[CallStrings missedCallWithIdentityChangeNotificationBodyWithCallerName], callerName];
            break;
        }
    }
    notification.alertBody = [NSString stringWithFormat:@"☎️ %@", alertMessage];

    [self presentNotification:notification identifier:localCallId];
     */
}

#pragma mark - Signal Messages

- (void)notifyUserForErrorMessage:(TSErrorMessage *)message
                           thread:(TSThread *)thread
                      transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    OWSAssert(message);

    if (!thread) {
        OWSFailDebug(
            @"%@ unexpected notification not associated with a thread: %@.", self.logTag, [message class]);
        [self notifyUserForThreadlessErrorMessage:message transaction:transaction];
        return;
    }

    NSString *messageText = [message previewTextWithTransaction:transaction];

    [transaction
        addCompletionQueue:nil
           completionBlock:^() {
               if (thread.isMuted) {
                   return;
               }

               BOOL shouldPlaySound = [self shouldPlaySoundForNotification];

               if (([UIApplication sharedApplication].applicationState != UIApplicationStateActive) && messageText) {
                   UILocalNotification *notification = [[UILocalNotification alloc] init];
                   notification.userInfo = @{ Signal_Thread_UserInfo_Key : thread.uniqueId };
                   if (shouldPlaySound) {
                       OWSSound sound = [OWSSounds notificationSoundForThread:thread];
                       notification.soundName = [OWSSounds filenameForSound:sound];
                   }

                   NSString *alertBodyString = @"";

                   NSString *authorName = [thread displayName];
                   switch (self.notificationPreviewType) {
                       case NotificationNamePreview:
                       case NotificationNameNoPreview:
                           if (authorName.length > 0) {
                               alertBodyString = [NSString stringWithFormat:@"%@: %@", authorName, messageText];
                           } else {
                               alertBodyString = messageText;
                           }
                           break;
                       case NotificationNoNameNoPreview:
                           alertBodyString = messageText;
                           break;
                   }
                   notification.alertBody = alertBodyString;

                   [[PushManager sharedManager] presentNotification:notification checkForCancel:NO];
               } else {
                   if (shouldPlaySound && [Environment.preferences soundInForeground]) {
                       OWSSound sound = [OWSSounds notificationSoundForThread:thread];
                       SystemSoundID soundId = [OWSSounds systemSoundIDForSound:sound quiet:YES];
                       // Vibrate, respect silent switch, respect "Alert" volume, not media volume.
                       AudioServicesPlayAlertSound(soundId);
                   }
               }
           }];
}

- (void)notifyUserForThreadlessErrorMessage:(TSErrorMessage *)message
                                transaction:(YapDatabaseReadWriteTransaction *)transaction;
{
    OWSAssert(message);

    NSString *messageText = [message previewTextWithTransaction:transaction];

    [transaction
        addCompletionQueue:nil
           completionBlock:^() {
               BOOL shouldPlaySound = [self shouldPlaySoundForNotification];

               if (([UIApplication sharedApplication].applicationState != UIApplicationStateActive) && messageText) {
                   UILocalNotification *notification = [[UILocalNotification alloc] init];
                   if (shouldPlaySound) {
                       OWSSound sound = [OWSSounds globalNotificationSound];
                       notification.soundName = [OWSSounds filenameForSound:sound];
                   }

                   NSString *alertBodyString = messageText;
                   notification.alertBody = alertBodyString;

                   [[PushManager sharedManager] presentNotification:notification checkForCancel:NO];
               } else {
                   if (shouldPlaySound && [Environment.preferences soundInForeground]) {
                       OWSSound sound = [OWSSounds globalNotificationSound];
                       SystemSoundID soundId = [OWSSounds systemSoundIDForSound:sound quiet:YES];
                       // Vibrate, respect silent switch, respect "Alert" volume, not media volume.
                       AudioServicesPlayAlertSound(soundId);
                   }
               }
           }];
}

- (void)notifyUserForIncomingMessage:(TSIncomingMessage *)message
                            inThread:(TSThread *)thread
                     contactsManager:(id<ContactsManagerProtocol>)contactsManager
                         transaction:(YapDatabaseReadTransaction *)transaction
{
    OWSAssert(message);
    OWSAssert(thread);
    OWSAssert(contactsManager);

    // While batch processing, some of the necessary changes have not been commited.
    NSString *rawMessageText = [message previewTextWithTransaction:transaction];

    // iOS strips anything that looks like a printf formatting character from
    // the notification body, so if we want to dispay a literal "%" in a notification
    // it must be escaped.
    // see https://developer.apple.com/documentation/uikit/uilocalnotification/1616646-alertbody
    // for more details.
    NSString *messageText = [DisplayableText filterNotificationText:rawMessageText];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (thread.isMuted) {
            return;
        }

        BOOL shouldPlaySound = [self shouldPlaySoundForNotification];

        NSString *senderName = [contactsManager displayNameForRecipientId:message.authorId];

        if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive && messageText) {
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            if (shouldPlaySound) {
                OWSSound sound = [OWSSounds notificationSoundForThread:thread];
                notification.soundName = [OWSSounds filenameForSound:sound];
            }

            switch (self.notificationPreviewType) {
                case NotificationNamePreview: {

                    // Don't reply from lockscreen if anyone in this conversation is
                    // "no longer verified".
                    BOOL isNoLongerVerified = NO;
                    for (NSString *recipientId in thread.participantIds) {
                        if ([OWSIdentityManager.sharedManager verificationStateForRecipientId:recipientId]
                            == OWSVerificationStateNoLongerVerified) {
                            isNoLongerVerified = YES;
                            break;
                        }
                    }

                    notification.category = (isNoLongerVerified ? Signal_Full_New_Message_Category_No_Longer_Verified
                                                                : Signal_Full_New_Message_Category);
                    notification.userInfo = @{
                        Signal_Thread_UserInfo_Key : thread.uniqueId,
                        Signal_Message_UserInfo_Key : message.uniqueId
                    };

                    notification.category = Signal_Full_New_Message_Category;
                    notification.userInfo =
                    @{Signal_Thread_UserInfo_Key : thread.uniqueId, Signal_Message_UserInfo_Key : message.uniqueId};
                    if ([senderName isEqualToString:thread.displayName]) {
                        notification.alertBody = [NSString stringWithFormat:@"%@: %@", senderName, messageText];
                    } else {
                        notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"APN_MESSAGE_IN_GROUP_DETAILED", nil), senderName, thread.displayName, messageText];
                    }

                    break;
                }
                case NotificationNameNoPreview: {
                    notification.userInfo = @{Signal_Thread_UserInfo_Key : thread.uniqueId};
                    notification.alertBody =
                    [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"APN_MESSAGE_FROM", nil), senderName];
                    break;
                }
                case NotificationNoNameNoPreview:
                    notification.alertBody = NSLocalizedString(@"APN_Message", nil);
                    break;
                default:
                    DDLogWarn(@"unknown notification preview type: %lu", (unsigned long)self.notificationPreviewType);
                    notification.alertBody = NSLocalizedString(@"APN_Message", nil);
                    break;
            }

            [[PushManager sharedManager] presentNotification:notification checkForCancel:YES];
        } else {
            if (shouldPlaySound && [Environment.preferences soundInForeground]) {
                OWSSound sound = [OWSSounds notificationSoundForThread:thread];
                SystemSoundID soundId = [OWSSounds systemSoundIDForSound:sound quiet:YES];
                // Vibrate, respect silent switch, respect "Alert" volume, not media volume.
                AudioServicesPlayAlertSound(soundId);
            }
        }
    });
}

- (BOOL)shouldPlaySoundForNotification
{
    @synchronized(self)
    {
        // Play no more than 2 notification sounds in a given
        // five-second window.
        const CGFloat kNotificationWindowSeconds = 5.f;
        const NSUInteger kMaxNotificationRate = 2;

        // Cull obsolete notification timestamps from the thread's notification history.
        while (self.notificationHistory.count > 0) {
            NSDate *notificationTimestamp = self.notificationHistory[0];
            CGFloat notificationAgeSeconds = fabs(notificationTimestamp.timeIntervalSinceNow);
            if (notificationAgeSeconds > kNotificationWindowSeconds) {
                [self.notificationHistory removeObjectAtIndex:0];
            } else {
                break;
            }
        }

        // Ignore notifications if necessary.
        BOOL shouldPlaySound = self.notificationHistory.count < kMaxNotificationRate;

        if (shouldPlaySound) {
            // Add new notification timestamp to the thread's notification history.
            NSDate *newNotificationTimestamp = [NSDate new];
            [self.notificationHistory addObject:newNotificationTimestamp];

            return YES;
        } else {
            DDLogDebug(@"Skipping sound for notification");
            return NO;
        }
    }
}

#pragma mark - Util

- (NotificationType)notificationPreviewType
{
    OWSPreferences *prefs = [Environment current].preferences;
    return prefs.notificationPreviewType;
}

- (void)presentNotification:(UILocalNotification *)notification identifier:(NSString *)identifier
{
    notification.alertBody = notification.alertBody.filterStringForDisplay;

    DispatchMainThreadSafe(^{
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
            DDLogWarn(@"%@ skipping notification; app is in foreground and active.", self.logTag);
            return;
        }

        // Replace any existing notification
        // e.g. when an "Incoming Call" notification gets replaced with a "Missed Call" notification.
        if (self.currentNotifications[identifier]) {
            [self cancelNotificationWithIdentifier:identifier];
        }

        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        DDLogDebug(@"%@ presenting notification with identifier: %@", self.logTag, identifier);

        self.currentNotifications[identifier] = notification;
    });
}

- (void)cancelNotificationWithIdentifier:(NSString *)identifier
{
    DispatchMainThreadSafe(^{
        UILocalNotification *notification = self.currentNotifications[identifier];
        if (!notification) {
            DDLogWarn(
                @"%@ Couldn't cancel notification because none was found with identifier: %@", self.logTag, identifier);
            return;
        }
        [self.currentNotifications removeObjectForKey:identifier];

        [[UIApplication sharedApplication] cancelLocalNotification:notification];
    });
}

#ifdef DEBUG

+ (void)presentDebugNotification
{
    OWSAssertIsOnMainThread();

    UILocalNotification *notification = [UILocalNotification new];
    notification.category = Signal_Full_New_Message_Category;
    notification.soundName = [OWSSounds filenameForSound:OWSSound_DefaultiOSIncomingRingtone];
    notification.alertBody = @"test";

    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

#endif

- (void)clearAllNotifications
{
    OWSAssertIsOnMainThread();

    [self.currentNotifications removeAllObjects];
}

@end
