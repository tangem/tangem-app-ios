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
    @Injected(\.mobileFinishActivationManager) private var mobileFinishActivationManager: MobileFinishActivationManager

    public private(set) var pendingAction: IncomingAction?
    private var responders = OrderedWeakObjectsCollection<IncomingActionResponder>()
    private lazy var parser = IncomingActionParser()
    private let urlValidator: IncomingURLValidator
    private var cancellable: AnyCancellable?

    public init(urlValidator: IncomingURLValidator = CommonIncomingURLValidator()) {
        self.urlValidator = urlValidator
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
    private func _handleIncomingURL(_ url: URL) -> Bool {
        AppLogger.info("Received deeplink: \(url.absoluteString)")

        guard let action = parser.parseIncomingURL(url) else {
            return false
        }

        mobileFinishActivationManager.onIncoming(action: action)

        pendingAction = action
        tryHandleLastAction()
        return true
    }

    private func handlePushNotificationEvent(_ event: PushNotificationsEvent) {
        guard case .receivedResponse(let response) = event else {
            return
        }

        let deeplinkURL = [Constants.deeplinkKey, Constants.externalLinkKey]
            .compactMap { response.notification.request.content.userInfo[$0] as? String }
            .first

        let userInfo = response.notification.request.content.userInfo

        if let deeplinkURL {
            tryHandleDeeplinkUrlByDeeplinkKey(with: deeplinkURL)
        } else {
            // A temporary crutch, while the push of deeplink transactions is not formed on the back, but is collected locally
            tryHandleDeeplinkUrlByTransactionPush(with: userInfo)
        }
    }

    private func tryHandleDeeplinkUrlByDeeplinkKey(with deeplinkURL: String) {
        if let url = URL(string: deeplinkURL) {
            _handleIncomingURL(url)
        }
    }

    private func tryHandleDeeplinkUrlByTransactionPush(with userInfo: [AnyHashable: Any]) {
        let filteredUserInfo = userInfo.filter { !($0.value as? String == "null") }
        let paramsConstants = IncomingActionConstants.DeeplinkParams.self
        let typeConstants = IncomingActionConstants.DeeplinkType.self

        let validTypes = [
            typeConstants.incomeTransaction.rawValue,
            typeConstants.swapStatusUpdate.rawValue,
            typeConstants.onrampStatusUpdate.rawValue,
        ]

        guard
            let networkId = filteredUserInfo[paramsConstants.networkId] as? String,
            let tokenId = filteredUserInfo[paramsConstants.tokenId] as? String,
            let userWalletId = filteredUserInfo[paramsConstants.userWalletId] as? String,
            let type = filteredUserInfo[paramsConstants.type] as? String,
            validTypes.contains(type)
        else {
            return
        }

        let derivationPath = filteredUserInfo[paramsConstants.derivationPath] as? String

        let transactionPushURLHelper = TransactionPushActionURLHelper(
            type: type,
            networkId: networkId,
            tokenId: tokenId,
            userWalletId: userWalletId,
            derivationPath: derivationPath
        )

        let handleUrl = transactionPushURLHelper.buildURL(scheme: .withoutRedirectUniversalLink)
        _handleIncomingURL(handleUrl)
    }
}

// MARK: - IncomingActionManaging

extension CommonIncomingActionManager: IncomingActionManaging {
    public func checkForPendingActions() {
        if pendingAction != nil {
            tryHandleLastAction()
        }
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

    public func discardIncomingAction(if shouldDiscard: (IncomingAction) -> Bool) {
        if let action = pendingAction, shouldDiscard(action) {
            pendingAction = nil
        }
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

    public func handleIncomingURL(_ url: URL) -> Bool {
        _handleIncomingURL(url)
    }
}

// MARK: - Constants

extension CommonIncomingActionManager {
    enum Constants: CaseIterable {
        /// Key used to extract an external URL from push notification payload (e.g., "link": "https://...").
        static let externalLinkKey = "link"
        /// Key used to extract a deeplink from push notification payload.
        static let deeplinkKey = "deeplink"
    }
}
