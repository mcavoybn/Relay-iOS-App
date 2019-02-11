//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation
import PromiseKit
import CallKit
import RelayServiceKit
import RelayMessaging
import WebRTC

protocol CallUIAdaptee {
}

// Shared default implementations
extension CallUIAdaptee {
}

/**
 * Notify the user of call related activities.
 * Driven by either a CallKit or System notifications adaptee
 */
@objc public class CallUIAdapter: NSObject, ConferenceCallServiceDelegate {
    func createdConferenceCall(call: ConferenceCall) {
        Logger.debug("TODO: handle createdConferenceCall")
    }
}
