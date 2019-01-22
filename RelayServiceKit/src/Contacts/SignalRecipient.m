//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "SignalRecipient.h"
#import "TSAccountManager.h"
#import <YapDatabase/YapDatabaseConnection.h>

NS_ASSUME_NONNULL_BEGIN

@interface SignalRecipient ()

@property (nonatomic) NSOrderedSet *devices;

@end

#pragma mark -

@implementation SignalRecipient

+ (instancetype)getOrBuildUnsavedRecipientForRecipientId:(NSString *)recipientId
                                             transaction:(YapDatabaseReadTransaction *)transaction
{
    OWSAssert(transaction);
    OWSAssert(recipientId.length > 0);
    
    SignalRecipient *_Nullable recipient = [self registeredRecipientForRecipientId:recipientId transaction:transaction];
    if (!recipient) {
        recipient = [[self alloc] initWithTextSecureIdentifier:recipientId];
    }
    return recipient;
}

- (instancetype)initWithTextSecureIdentifier:(NSString *)textSecureIdentifier
{
    self = [super initWithUniqueId:textSecureIdentifier];
    if (!self) {
        return self;
    }

    OWSAssert([TSAccountManager localUID].length > 0);
    if ([[TSAccountManager localUID] isEqualToString:textSecureIdentifier]) {
        // Default to no devices.
        //
        // This instance represents our own account and is used for sending
        // sync message to linked devices.  We shouldn't have any linked devices
        // yet when we create the "self" SignalRecipient, and we don't need to
        // send sync messages to the primary - we ARE the primary.
        _devices = [NSOrderedSet new];
    } else {
        // Default to sending to just primary device.
        //
        // MessageSender will correct this if it is wrong the next time
        // we send a message to this recipient.
        _devices = [NSOrderedSet orderedSetWithObject:@(1)];
    }

    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (!self) {
        return self;
    }

    if (_devices == nil) {
        _devices = [NSOrderedSet new];
    }

    if ([self.uniqueId isEqual:[TSAccountManager localUID]] && [self.devices containsObject:@(1)]) {
        OWSFail(@"%@ in %s self as recipient device", self.logTag, __PRETTY_FUNCTION__);
    }

    return self;
}


+ (nullable instancetype)registeredRecipientForRecipientId:(NSString *)recipientId
                                               transaction:(YapDatabaseReadTransaction *)transaction
{
    OWSAssert(transaction);
    OWSAssert(recipientId.length > 0);

    return [self fetchObjectWithUniqueID:recipientId transaction:transaction];
}

+ (nullable instancetype)recipientForRecipientId:(NSString *)recipientId
{
    OWSAssert(recipientId.length > 0);

    __block SignalRecipient *recipient;
    [self.dbReadConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        recipient = [self registeredRecipientForRecipientId:recipientId transaction:transaction];
    }];
    return recipient;
}

// TODO This method should probably live on the TSAccountManager rather than grabbing a global singleton.
+ (instancetype)selfRecipient
{
    SignalRecipient *myself = [self recipientForRecipientId:[TSAccountManager localUID]];
    if (!myself) {
        myself = [[self alloc] initWithTextSecureIdentifier:[TSAccountManager localUID]];
    }
    return myself;
}

- (void)addDevices:(NSSet *)devices
{
    OWSAssert(devices.count > 0);
    
    if ([self.uniqueId isEqual:[TSAccountManager localUID]] && [devices containsObject:@(1)]) {
        OWSFail(@"%@ in %s adding self as recipient device", self.logTag, __PRETTY_FUNCTION__);
        return;
    }

    NSMutableOrderedSet *updatedDevices = [self.devices mutableCopy];
    [updatedDevices unionSet:devices];
    self.devices = [updatedDevices copy];
}

- (void)removeDevices:(NSSet *)devices
{
    OWSAssert(devices.count > 0);

    NSMutableOrderedSet *updatedDevices = [self.devices mutableCopy];
    [updatedDevices minusSet:devices];
    self.devices = [updatedDevices copy];
}

- (void)addDevicesToRegisteredRecipient:(NSSet *)devices transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    OWSAssert(transaction);
    OWSAssert(devices.count > 0);
    
    [self addDevices:devices];

    SignalRecipient *latest =
        [SignalRecipient markRecipientAsRegisteredAndGet:self.recipientId transaction:transaction];

    if ([devices isSubsetOfSet:latest.devices.set]) {
        return;
    }
    DDLogDebug(@"%@ adding devices: %@, to recipient: %@", self.logTag, devices, latest.recipientId);

    [latest addDevices:devices];
    [latest saveWithTransaction_internal:transaction];
}

- (void)removeDevicesFromRecipient:(NSSet *)devices transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    OWSAssert(transaction);
    OWSAssert(devices.count > 0);

    [self removeDevices:devices];

    SignalRecipient *_Nullable latest =
        [SignalRecipient registeredRecipientForRecipientId:self.recipientId transaction:transaction];

    if (!latest) {
        return;
    }
    if (![devices intersectsSet:latest.devices.set]) {
        return;
    }
    DDLogDebug(@"%@ removing devices: %@, from registered recipient: %@", self.logTag, devices, latest.recipientId);

    [latest removeDevices:devices];
    [latest saveWithTransaction_internal:transaction];
}

- (NSString *)recipientId
{
    return self.uniqueId;
}

- (NSComparisonResult)compare:(SignalRecipient *)other
{
    return [self.recipientId compare:other.recipientId];
}

- (void)saveWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    // We only want to mutate the persisted SignalRecipients in the database
    // using other methods of this class, e.g. markRecipientAsRegistered...
    // to create, addDevices and removeDevices to mutate.  We're trying to
    // be strict about using persisted SignalRecipients as a cache to
    // reflect "last known registration status".  Forcing our codebase to
    // use those methods helps ensure that we update the cache deliberately.
    OWSFailDebug(@"%@ Don't call saveWithTransaction from outside this class.", self.logTag);

    [self saveWithTransaction_internal:transaction];
}

- (void)saveWithTransaction_internal:(YapDatabaseReadWriteTransaction *)transaction
{
    [super saveWithTransaction:transaction];

    DDLogVerbose(@"%@ saved signal recipient: %@", self.logTag, self.recipientId);
}

+ (BOOL)isRegisteredRecipient:(NSString *)recipientId transaction:(YapDatabaseReadTransaction *)transaction
{
    SignalRecipient *_Nullable instance = [self registeredRecipientForRecipientId:recipientId transaction:transaction];
    return instance != nil;
}

+ (SignalRecipient *)markRecipientAsRegisteredAndGet:(NSString *)recipientId
                                         transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    OWSAssert(transaction);
    OWSAssert(recipientId.length > 0);

    SignalRecipient *_Nullable instance = [self registeredRecipientForRecipientId:recipientId transaction:transaction];

    if (!instance) {
        DDLogDebug(@"%@ creating recipient: %@", self.logTag, recipientId);

        instance = [[self alloc] initWithTextSecureIdentifier:recipientId];
        [instance saveWithTransaction_internal:transaction];
    }
    return instance;
}

+ (void)markRecipientAsRegistered:(NSString *)recipientId
                         deviceId:(UInt32)deviceId
                      transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    OWSAssert(transaction);
    OWSAssert(recipientId.length > 0);

    SignalRecipient *recipient = [self markRecipientAsRegisteredAndGet:recipientId transaction:transaction];
    if (![recipient.devices containsObject:@(deviceId)]) {
        DDLogDebug(@"%@ in %s adding device %u to existing recipient.",
                   self.logTag,
                   __PRETTY_FUNCTION__,
                   (unsigned int)deviceId);
        
        [recipient addDevices:[NSSet setWithObject:@(deviceId)]];
        [recipient saveWithTransaction_internal:transaction];
    }
}

+ (void)removeUnregisteredRecipient:(NSString *)recipientId transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    OWSAssert(transaction);
    OWSAssert(recipientId.length > 0);

    SignalRecipient *_Nullable instance = [self registeredRecipientForRecipientId:recipientId transaction:transaction];
    if (!instance) {
        return;
    }
    DDLogDebug(@"%@ removing recipient: %@", self.logTag, recipientId);
    [instance removeWithTransaction:transaction];
}

@end

NS_ASSUME_NONNULL_END
