//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import XCTest
import PromiseKit
import RelayServiceKit
@testable import Signal

struct VerificationFailedError: Error { }
struct FailedToGetRPRegistrationTokenError: Error { }

enum PushNotificationRequestResult: String {
    case FailTSOnly = "FailTSOnly",
    FailRPOnly = "FailRPOnly",
    FailBoth = "FailBoth",
    Succeed = "Succeed"
}

class FailingTSAccountManager: TSAccountManager {
    override public init(networkManager: TSNetworkManager, primaryStorage: OWSPrimaryStorage) {
        AssertIsOnMainThread(file: #function)

        super.init(networkManager: networkManager, primaryStorage: primaryStorage)

        self.uuidAwaitingVerification = "+13235555555"
    }

    override func verifyAccount(withCode: String,
                                pin: String?,
                                success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        failure(VerificationFailedError())
    }

    override func registerForPushNotifications(pushToken: String, voipToken: String, success successHandler: @escaping () -> Void, failure failureHandler: @escaping (Error) -> Void) {
        if pushToken == PushNotificationRequestResult.FailTSOnly.rawValue || pushToken == PushNotificationRequestResult.FailBoth.rawValue {
            failureHandler(OWSErrorMakeUnableToProcessServerResponseError())
        } else {
            successHandler()
        }
    }
}

class VerifyingTSAccountManager: FailingTSAccountManager {
    override func verifyAccount(withCode: String,
                                pin: String?,
                                success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        success()
    }

    override func registerForManualMessageFetching(success successBlock: @escaping () -> Void, failure failureBlock: @escaping (Error) -> Void) {
        successBlock()
    }
}

class TokenObtainingTSAccountManager: VerifyingTSAccountManager {
}

class AccountManagerTest: XCTestCase {

    let tsAccountManager = FailingTSAccountManager(networkManager: TSNetworkManager.shared(), primaryStorage: OWSPrimaryStorage.shared())
    var preferences = OWSPreferences()

    func testRegisterWhenEmptyCode() {
        let accountManager = AccountManager(textSecureAccountManager: tsAccountManager, preferences: self.preferences)

        let expectation = self.expectation(description: "should fail")

        firstly {
            accountManager.register(verificationCode: "", pin: "")
        }.done {
            XCTFail("Should fail")
        }.catch { error in
            let nserror = error as NSError
            if OWSErrorCode(rawValue: nserror.code) == OWSErrorCode.userError {
                expectation.fulfill()
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }.retainUntilComplete()

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testRegisterWhenVerificationFails() {
        let accountManager = AccountManager(textSecureAccountManager: tsAccountManager, preferences: self.preferences)

        let expectation = self.expectation(description: "should fail")

        firstly {
            accountManager.register(verificationCode: "123456", pin: "")
        }.done {
            XCTFail("Should fail")
        }.catch { error in
            if error is VerificationFailedError {
                expectation.fulfill()
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }.retainUntilComplete()

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testSuccessfulRegistration() {
        Environment.clearCurrentForTests()
        Environment.setCurrent(Release.releaseEnvironment())

        let tsAccountManager = TokenObtainingTSAccountManager(networkManager: TSNetworkManager.shared(), primaryStorage: OWSPrimaryStorage.shared())

        let accountManager = AccountManager(textSecureAccountManager: tsAccountManager, preferences: self.preferences)

        let expectation = self.expectation(description: "should succeed")

        firstly {
            accountManager.register(verificationCode: "123456", pin: "")
        }.done {
            expectation.fulfill()
        }.catch { error in
            XCTFail("Unexpected error: \(error)")
        }.retainUntilComplete()

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testUpdatePushTokens() {
        let accountManager = AccountManager(textSecureAccountManager: tsAccountManager, preferences: self.preferences)

        let expectation = self.expectation(description: "should fail")

        firstly {
            accountManager.updatePushTokens(pushToken: PushNotificationRequestResult.FailTSOnly.rawValue, voipToken: "whatever")
            }.done {            XCTFail("Expected to fail.")
        }.catch { _ in
            expectation.fulfill()
        }.retainUntilComplete()

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

}
