//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSNotifyRemoteOfUpdatedDisappearingConfigurationJob.h"
#import "OWSDisappearingMessagesConfigurationMessage.h"
#import "MessageSender.h"

NS_ASSUME_NONNULL_BEGIN

@interface OWSNotifyRemoteOfUpdatedDisappearingConfigurationJob ()

@property (nonatomic, readonly) OWSDisappearingMessagesConfiguration *configuration;
@property (nonatomic, readonly) MessageSender *messageSender;
@property (nonatomic, readonly) TSThread *thread;

@end

@implementation OWSNotifyRemoteOfUpdatedDisappearingConfigurationJob

- (instancetype)initWithConfiguration:(OWSDisappearingMessagesConfiguration *)configuration
                               thread:(TSThread *)thread
                        messageSender:(MessageSender *)messageSender
{
    self = [super init];
    if (!self) {
        return self;
    }

    _thread = thread;
    _configuration = configuration;
    _messageSender = messageSender;

    return self;
}

+ (void)runWithConfiguration:(OWSDisappearingMessagesConfiguration *)configuration
                      thread:(TSThread *)thread
               messageSender:(MessageSender *)messageSender
{
    OWSNotifyRemoteOfUpdatedDisappearingConfigurationJob *job =
        [[self alloc] initWithConfiguration:configuration thread:thread messageSender:messageSender];
    [job run];
}

- (void)run
{
    OWSDisappearingMessagesConfigurationMessage *message =
        [[OWSDisappearingMessagesConfigurationMessage alloc] initWithConfiguration:self.configuration
                                                                            thread:self.thread];

    [self.messageSender enqueueMessage:message
        success:^{
            DDLogDebug(
                @"%@ Successfully notified %@ of new disappearing messages configuration", self.logTag, self.thread);
        }
        failure:^(NSError *error) {
            DDLogError(@"%@ Failed to notify %@ of new disappearing messages configuration with error: %@",
                self.logTag,
                self.thread,
                error);
        }];
}

@end

NS_ASSUME_NONNULL_END
