//
//  CallController.swift
//  Relay
//
//  Created by Greg Perkins on 1/28/19.
//  Copyright © 2019 Forsta, Inc. All rights reserved.
//

import Foundation
import RelayServiceKit
import WebRTC
import PromiseKit

protocol ConferenceCallServiceDelegate: class {
    func createdConferenceCall(call: ConferenceCall)
}

@objc public class ConferenceCallService: NSObject, FLCallMessageHandler {
    static let rtcFactory = RTCPeerConnectionFactory()
    @objc static let shared = ConferenceCallService()
    
    // Exposed by environment.m
    internal let notificationsAdapter = CallNotificationsAdapter()
    @objc public var callUIAdapter: CallUIAdapter?
    
    let rtcQueue = DispatchQueue(label: "WebRTCDanceCard")
    lazy var iceServers: Promise<[RTCIceServer]> = ConferenceCallService.getIceServers();
    var delegates = [Weak<ConferenceCallServiceDelegate>]()

    var conferenceCall: ConferenceCall?  // this can be a collection in the future, indexed by callId
    
    required override init() {
        super.init()
        
        if #available(iOS 10.0, *) {
            self.callUIAdapter = CallUIAdapter(callService: self, notificationsAdapter: self.notificationsAdapter)
        }
    }
    

    func addDelegate(delegate: ConferenceCallServiceDelegate) {
        AssertIsOnMainThread(file: #function)
        delegates.append(Weak(value: delegate))
    }
    
    func removeDelegate(_ delegate: ConferenceCallServiceDelegate) {
        AssertIsOnMainThread(file: #function)
        while let index = delegates.index(where: { $0.value === delegate }) {
            delegates.remove(at: index)
        }
    }
    
    func notifyDelegates(todo: (_ theDelegate: ConferenceCallServiceDelegate) -> Void) {
        for delegate in delegates {
            if delegate.value != nil {
                todo(delegate.value!)
            }
        }
    }
        

    public func receivedOffer(with thread: TSThread, callId: String, senderId: String, peerId: String, originatorId: String, sessionDescription: String) {
        if conferenceCall != nil && conferenceCall?.callId != callId {
            Logger.debug("Ignoring call offer from/for a new call")
            return
        }
        if conferenceCall == nil {
            conferenceCall = ConferenceCall(direction: .incoming, thread: thread, callId: callId, originatorId: originatorId)
            notifyDelegates(todo: { del in del.createdConferenceCall(call: conferenceCall!) })
        }
        conferenceCall!.handleOffer(senderId: senderId, peerId: peerId, sessionDescription: sessionDescription)
        self.callUIAdapter?.reportIncomingCall(conferenceCall!, thread: thread)
    }

    public func receivedAcceptOffer(with thread: TSThread, callId: String, peerId: String, sessionDescription: String) {
        if conferenceCall == nil || (conferenceCall != nil && conferenceCall?.callId != callId) {
            Logger.debug("Ignoring ice candidates from/for an unknown call")
            return
        }
        conferenceCall!.handleAcceptOffer(peerId: peerId, sessionDescription: sessionDescription)
    }
    
    public func receivedIceCandidates(with thread: TSThread, callId: String, peerId: String, iceCandidates: [Any]) {
        if conferenceCall == nil || (conferenceCall != nil && conferenceCall?.callId != callId) {
            Logger.debug("Ignoring ice candidates from/for an unknown call")
            return
        }
        conferenceCall?.handleRemoteIceCandidates(peerId: peerId, iceCandidates: iceCandidates)
    }
    
    public func receivedLeave(with thread: TSThread, callId: String, peerId: String) {
        if conferenceCall == nil || (conferenceCall != nil && conferenceCall?.callId != callId) {
            Logger.debug("Ignoring leave from/for an unknown call")
            return
        }
        
        conferenceCall?.handlePeerLeave(peerId: peerId);
    }
    
    @objc public func callOut(with thread: TSThread) {
//        if conferenceCall != nil {
//            Logger.debug("no new call while existing call is in place")
//            return
//        }
        let newCallId = NSUUID().uuidString.lowercased()
        let originatorId = TSAccountManager.localUID()!
        conferenceCall = ConferenceCall(direction: .outgoing, thread: thread, callId: newCallId, originatorId: originatorId)
        notifyDelegates(todo: { del in del.createdConferenceCall(call: conferenceCall!) })
        conferenceCall!.inviteMissingParticipants()
    }
    
    private static func getIceServers() -> Promise<[RTCIceServer]> {
        AssertIsOnMainThread(file: #function)
        
        return firstly {
            SignalApp.shared().accountManager.getTurnServerInfo()
        }.map { turnServerInfo -> [RTCIceServer] in
            Logger.debug("got turn server urls: \(turnServerInfo.urls)")
            
            return turnServerInfo.urls.map { url in
                    if url.hasPrefix("turn") {
                        // Only "turn:" servers require authentication. Don't include the credentials to other ICE servers
                        // as 1.) they aren't used, and 2.) the non-turn servers might not be under our control.
                        // e.g. we use a public fallback STUN server.
                        return RTCIceServer(urlStrings: [url], username: turnServerInfo.username, credential: turnServerInfo.password)
                    } else {
                        return RTCIceServer(urlStrings: [url])
                    }
                } + [RTCIceServer(urlStrings: [fallbackIceServerUrl])]
        }.recover { (error: Error) -> Guarantee<[RTCIceServer]> in
            Logger.error("fetching ICE servers failed with error: \(error)")
            Logger.warn("using fallback ICE Server")
            
            return Guarantee.value([RTCIceServer(urlStrings: [fallbackIceServerUrl])])
        }
    }

    // MARK: - Observers
    
    // The observer-related methods should be invoked on the main thread.
    func addObserverAndSyncState(observer: ConferenceCallServiceDelegate) {
        AssertIsOnMainThread(file: #function)
        
        delegates.append(Weak(value: observer))
    }
    
    // The observer-related methods should be invoked on the main thread.
    func removeObserver(_ observer: ConferenceCallServiceDelegate) {
        AssertIsOnMainThread(file: #function)
        
        while let index = delegates.index(where: { $0.value === observer }) {
            delegates.remove(at: index)
        }
    }
    
    // The observer-related methods should be invoked on the main thread.
    func removeAllObservers() {
        AssertIsOnMainThread(file: #function)
        
        delegates = []
    }

}

extension ConferenceCallService : ConferenceCallDelegate {
    func stateDidChange(call: ConferenceCall, state: ConferenceCallState) {
        guard call == self.conferenceCall else {
            Logger.debug("Dropping stale call reference.")
            return
        }
        
        switch state {
        case .ringing:
            do {
                // Short UI for outgoing
            }
        case .rejected:
            do {
                // Hang it up
            }
        case .joined:
            do {
                // For outgoing notify UI
                // For incoming display incoming call UI
                self.callUIAdapter!.showCall(call)
            }
        case .left:
            do {
                // Hang it up
            }
        case .failed:
            do {
                
            }
        }
    }
    
    func peerConnectionDidConnect(peerId: String) {
        // stub
    }
    
    
}
