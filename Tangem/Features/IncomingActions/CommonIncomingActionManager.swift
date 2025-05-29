//
//  CommonIncomingActionManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public class CommonIncomingActionManager {
    public private(set) var pendingAction: IncomingAction?
    private var responders = OrderedWeakObjectsCollection<IncomingActionResponder>()
    private lazy var parser = IncomingActionParser()
    private let _didReceiveNavigationAction = PassthroughSubject<Void, Never>()

    public init() {}
}

// MARK: - IncomingActionManaging

extension CommonIncomingActionManager: IncomingActionManaging {
    public var didReceiveNavigationAction: AnyPublisher<Void, Never> {
        _didReceiveNavigationAction.eraseToAnyPublisher()
    }

    public func hasReferralNavigationAction() -> Bool {
        pendingAction == .referralProgram
    }

    public func becomeFirstResponder(_ responder: IncomingActionResponder) {
        if !responders.contains(responder) {
            responders.add(responder)
        }

        tryHandleLastAction()
    }

    public func resignFirstResponder(_ responder: IncomingActionResponder) {
        responders.remove(responder)
    }

    public func discardIncomingAction() {
        pendingAction = nil // discarded
    }

    private func tryHandleLastAction() {
        guard let pendingAction else {
            return
        }

        for responder in responders.allDelegates.reversed() {
            if responder.didReceiveIncomingAction(pendingAction) {
                self.pendingAction = nil // handled
                AppLogger.info("Incoming action handled: \(pendingAction)")
                break
            }
        }
    }
}

// MARK: - IncomingActionHandler

extension CommonIncomingActionManager: IncomingActionHandler {
    public func handleIntent(_ intent: String) -> Bool {
        AppLogger.info("Received intent: \(intent)")

        guard let action = parser.parseIntent(intent) else {
            return false
        }

        pendingAction = action
        tryHandleLastAction()
        return true
    }

    public func handleDeeplink(_ url: URL) -> Bool {
        AppLogger.info("Received deeplink: \(url.absoluteString)")

        guard let action = parser.parseDeeplink(url) else {
            return false
        }

        pendingAction = action
        tryHandleLastAction()

        _didReceiveNavigationAction.send()
        return true
    }
}
