//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "TSRequest.h"
#import "TSAccountManager.h"
#import "TSConstants.h"

@implementation TSRequest

@synthesize authUsername = _authUsername;
@synthesize authPassword = _authPassword;

- (id)initWithURL:(NSURL *)URL {
    OWSAssert(URL);
    self = [super initWithURL:URL
                  cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
              timeoutInterval:textSecureHTTPTimeOut];
    if (!self) {
        return nil;
    }

    _parameters = @{};
    self.shouldHaveAuthorizationHeaders = YES;

    return self;
}

- (instancetype)init
{
    OWSRaiseException(NSInternalInconsistencyException, @"You must use the initWithURL: method");
    return nil;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"

- (instancetype)initWithURL:(NSURL *)URL
                cachePolicy:(NSURLRequestCachePolicy)cachePolicy
            timeoutInterval:(NSTimeInterval)timeoutInterval
{
    OWSRaiseException(NSInternalInconsistencyException, @"You must use the initWithURL method");
    return nil;
}

- (instancetype)initWithURL:(NSURL *)URL
                     method:(NSString *)method
                 parameters:(nullable NSDictionary<NSString *, id> *)parameters
{
    OWSAssert(URL);
    OWSAssert(method.length > 0);
    OWSAssert(parameters);

    self = [super initWithURL:URL
                  cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
              timeoutInterval:textSecureHTTPTimeOut];
    if (!self) {
        return nil;
    }

    _parameters = parameters ?: @{};
    [self setHTTPMethod:method];
    self.shouldHaveAuthorizationHeaders = YES;

    return self;
}

+ (instancetype)requestWithUrl:(NSURL *)url
                        method:(NSString *)method
                    parameters:(nullable NSDictionary<NSString *, id> *)parameters
{
    return [[TSRequest alloc] initWithURL:url method:method parameters:parameters];
}

#pragma mark - Authorization

- (void)setAuthUsername:(nullable NSString *)authUsername
{
    OWSAssert(self.shouldHaveAuthorizationHeaders);

    @synchronized(self) {
        _authUsername = authUsername;
    }
}

- (void)setAuthPassword:(nullable NSString *)authPassword
{
    OWSAssert(self.shouldHaveAuthorizationHeaders);

    @synchronized(self) {
        _authPassword = authPassword;
    }
}

- (NSString *)authUsername
{
    OWSAssert(self.shouldHaveAuthorizationHeaders);

    @synchronized(self) {
        if (_authUsername == nil) {
            _authUsername = [TSAccountManager localUID];
        }
        return _authUsername;
    }
}

- (NSString *)authPassword
{
    OWSAssert(self.shouldHaveAuthorizationHeaders);

    @synchronized(self) {
        if (_authPassword == nil) {
            _authPassword = [TSAccountManager serverAuthToken];
        }
        return _authPassword;
    }
}

@end
