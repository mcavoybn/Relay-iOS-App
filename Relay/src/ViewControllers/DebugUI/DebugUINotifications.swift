//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation
import RelayServiceKit
import RelayMessaging

class DebugUINotifications: DebugUIPage {

    // MARK: Dependencies

    var notificationsManager: NotificationsManager {
        return SignalApp.shared().notificationsManager
    }
    var notificationsAdapter: CallNotificationsAdapter {
        return CallNotificationsAdapter() // totally bogus
    }
    var messageSender: MessageSender {
        return Environment.current().messageSender
    }
    var contactsManager: FLContactsManager {
        return Environment.current()!.contactsManager
    }

    // MARK: Overrides

    override func name() -> String {
        return "Notifications"
    }

    override func section(thread aThread: TSThread?) -> OWSTableSection? {
        guard let thread = aThread else {
            owsFailDebug("\(logTag) Notifications must specify thread.")
            return nil
        }

        var sectionItems = [
            OWSTableItem(title: "Last Incoming Message") { [weak self] in
                guard let strongSelf = self else {
                    return
                }

                Logger.info("\(strongSelf.logTag) scheduling notification for incoming message.")
                strongSelf.delayedNotificationDispatch {
                    Logger.info("\(strongSelf.logTag) dispatching")
                    OWSPrimaryStorage.shared().newDatabaseConnection().read { (transaction) in
                        guard let viewTransaction = transaction.ext(TSMessageDatabaseViewExtensionName) as? YapDatabaseViewTransaction  else {
                            owsFailDebug("unable to build view transaction")
                            return
                        }

                        guard let incomingMessage = viewTransaction.lastObject(inGroup: (aThread?.uniqueId)!  ) as? TSIncomingMessage else {
                            owsFailDebug("last message was not an incoming message.")
                            return
                        }
                        Logger.info("\(strongSelf.logTag) notifying user of incoming message")
                        strongSelf.notificationsManager.notifyUser(for: incomingMessage, in: thread, contactsManager: strongSelf.contactsManager, transaction: transaction)
                    }
                }
            }
        ]

        if thread.participantIds.count == 2 && thread.participantIds.contains(TSAccountManager.localUID()!) {
            sectionItems += [
                OWSTableItem(title: "Call Missed") { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }

                    strongSelf.delayedNotificationDispatchWithFakeCall(thread: thread) { call in
                        strongSelf.notificationsAdapter.presentMissedCall(call, callName: thread.title!)
                    }
                },
                OWSTableItem(title: "Call Rejected: New Safety Number") { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }

                    strongSelf.delayedNotificationDispatchWithFakeCall(thread: thread) { call in
                        strongSelf.notificationsAdapter.presentMissedCallBecauseOfNewIdentity(call: call, callerName: thread.title!)
                    }
                },
                OWSTableItem(title: "Call Rejected: No Longer Verified") { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }

                    strongSelf.delayedNotificationDispatchWithFakeCall(thread: thread) { call in
                        strongSelf.notificationsAdapter.presentMissedCallBecauseOfNoLongerVerifiedIdentity(call: call, callerName: thread.title!)
                    }
                }
            ]
        }

        return OWSTableSection(title: "Notifications have delay: \(kNotificationDelay)s", items: sectionItems)
    }

    // MARK: Helpers

    // After enqueing the notification you may want to background the app or lock the screen before it triggers, so
    // we give a little delay.
    let kNotificationDelay: TimeInterval = 5

    func delayedNotificationDispatch(block: @escaping () -> Void) {

        // Notifications won't sound if the app is suspended.
        let taskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + kNotificationDelay) {
            block()

            // We don't want to endBackgroundTask until *after* the notifications manager is done,
            // but it dispatches async without a completion handler, so we just wait a while extra.
            // This is fragile, but it's only for debug UI.
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
                UIApplication.shared.endBackgroundTask(taskIdentifier)
            }
        }
    }

    func delayedNotificationDispatchWithFakeCall(thread: TSThread, callBlock: @escaping (ConferenceCall) -> Void) {
    }
}
