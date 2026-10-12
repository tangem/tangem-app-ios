//
//  CommonIncomingActionManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

class CommonIncomingActionManager {
    @Injected(\.pushNotificationsEventsPublisher) private var pushNotificationsEventsPublisher: PushNotificationEventsPublishing

    private var responders = OrderedWeakObjectsCollection<IncomingActionResponder>()
    private lazy var parser = IncomingActionParser()
    private let incomingActionsSubject = PassthroughSubject<IncomingAction, Never>()
    private var cancellable: AnyCancellable?

    init() {
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

        receive(action)
        return true
    }

    private func handlePushNotificationEvent(_ event: PushNotificationsEvent) {
        guard case .receivedResponse(let response) = event else {
            return
        }

        let userInfo = response.notification.request.content.userInfo

        guard let action = parser.parse(push: userInfo) else {
            return
        }

        AppLogger.info("Received push with action: \(action)")
        receive(action)
    }
}

// MARK: - Dispatch

private extension CommonIncomingActionManager {
    /// An action that has just arrived from outside, as opposed to one handed back by a responder.
    func receive(_ action: IncomingAction) {
        incomingActionsSubject.send(action)
        handle(action)
    }

    /// Offers the action to the chain, newest responder first, until one shows it. Nobody showing it is the
    /// end of it: whoever wanted it kept for later had to be in the chain and take it.
    func handle(_ action: IncomingAction) {
        for responder in responders.allDelegates.reversed() where responder.didReceiveIncomingAction(action) {
            AppLogger.info("Incoming action handled: \(action)")
            return
        }

        AppLogger.info("Incoming action has nowhere to go: \(action)")
    }
}

// MARK: - IncomingActionManaging

extension CommonIncomingActionManager: IncomingActionManaging {
    var incomingActionsPublisher: AnyPublisher<IncomingAction, Never> {
        incomingActionsSubject.eraseToAnyPublisher()
    }

    func becomeFirstResponder(_ responder: IncomingActionResponder) {
        if !responders.contains(responder) {
            responders.add(responder)
        }
    }

    func resignFirstResponder(_ responder: IncomingActionResponder) {
        responders.remove(responder)
    }

    func deliver(_ action: IncomingAction) {
        handle(action)
    }
}

// MARK: - IncomingActionHandler

extension CommonIncomingActionManager: IncomingActionHandler {
    func handleIntent(_ intent: String) -> Bool {
        AppLogger.info("Received intent: \(intent)")

        guard let action = parser.parseIntent(intent) else {
            return false
        }

        receive(action)
        return true
    }

    @discardableResult
    func handleIncomingURL(_ url: URL) -> Bool {
        _handleIncomingURL(url)
    }
}
