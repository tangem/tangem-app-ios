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

    public init() {}
}

// MARK: - IncomingActionManaging

extension CommonIncomingActionManager: IncomingActionManaging {
    public func becomeFirstResponder(_ responder: IncomingActionResponder) {
        responders.add(responder)
        tryHandleLastAction()
    }

    public func resignFirstResponder(_ responder: IncomingActionResponder) {
        responders.remove(responder)
    }

    private func tryHandleLastAction() {
        guard let pendingAction else { return }

        for responder in responders.allDelegates.reversed() {
            if responder.didReceiveIncomingAction(pendingAction) {
                clearPendingAction()
                break
            }
        }
    }

    private func clearPendingAction() {
        pendingAction = nil
    }
}

// MARK: - IncomingActionHandler

extension CommonIncomingActionManager: IncomingActionHandler {
    public func handleIntent(_ intent: String) -> Bool {
        AppLog.shared.debug("Received intent: \(intent)")

        guard let action = parser.handleIntent(intent) else {
            return false
        }

        pendingAction = action
        tryHandleLastAction()
        return true
    }

    public func handleDeeplink(_ url: URL) -> Bool {
        AppLog.shared.debug("Received deeplink: \(url.absoluteString)")

        guard let action = parser.handleDeeplink(url) else {
            return false
        }

        pendingAction = action
        tryHandleLastAction()
        return true
    }
}

public enum IncomingAction {
    case walletConnect(WalletConnectRequestURI)
    case start // Run scan or request biometrics
}
