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
    @Injected(\.appLockController) private var appLockController: AppLockController
    @Injected(\.pushNotificationsEventsPublisher) private var pushNotificationsEventsPublisher: PushNotificationEventsPublishing

    public private(set) var pendingAction: IncomingAction?
    private var responders = OrderedWeakObjectsCollection<IncomingActionResponder>()
    private lazy var parser = IncomingActionParser()
    private var cancellable: AnyCancellable?

    public init() {
        bind()
    }

    private func bind() {
        cancellable = pushNotificationsEventsPublisher.eventsPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { manager, event in
                manager.handlePushNotificationEvent(event)
            }
    }

    @discardableResult
    private func _handleDeeplink(_ url: URL) -> Bool {
        AppLogger.info("Received deeplink: \(url.absoluteString)")

        guard let action = parser.parseDeeplink(url) else {
            return false
        }

        pendingAction = action
        tryHandleLastAction()
        return true
    }

    private func handlePushNotificationEvent(_ event: PushNotificationsEvent) {
        guard case .receivedResponse(let response) = event else {
            return
        }

        let userInfo = response.notification.request.content.userInfo

        if let deeplinkURL = userInfo[Constants.deeplinkKey] as? String {
            tryHandleDeeplinkUrlByDeeplinkKey(with: deeplinkURL)
        } else {
            // A temporary crutch, while the push of deeplink transactions is not formed on the back, but is collected locally
            tryHandleDeeplinkUrlByTransactionPush(with: userInfo)
        }
    }

    private func tryHandleDeeplinkUrlByDeeplinkKey(with deeplinkURL: String) {
        if let url = URL(string: deeplinkURL) {
            _handleDeeplink(url)
        }
    }

    private func tryHandleDeeplinkUrlByTransactionPush(with userInfo: [AnyHashable: Any]) {
        let constants = TransactionPushActionURLHelper.Constants.self

        guard
            let networkId = userInfo[constants.networkIdKey] as? String,
            let tokenId = userInfo[constants.tokenIdKey] as? String,
            let walletId = userInfo[constants.walletIdKey] as? String,
            let type = userInfo[constants.typeKey] as? String,
            type == constants.incomeTransaction
        else {
            return
        }

        let transactionPushURLHelper = TransactionPushActionURLHelper(
            type: type, // See documentation.
            networkId: networkId,
            tokenId: tokenId,
            walletId: walletId
        )

        let handleUrl = transactionPushURLHelper.buildURL(scheme: .withoutRedirectUniversalLink)
        _handleDeeplink(handleUrl)
    }
}

// MARK: - IncomingActionManaging

extension CommonIncomingActionManager: IncomingActionManaging {
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
        guard let pendingAction else { return }

        switch pendingAction {
        case .referralProgram where appLockController.isLocked: return
        default: break
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
        _handleDeeplink(url)
    }
}

// MARK: - Constants

extension CommonIncomingActionManager {
    enum Constants {
        static let deeplinkKey = "deeplink"
    }
}
