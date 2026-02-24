//
//  SendWithSwapNotificationManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import CombineExt

class SendWithSwapNotificationManager {
    private weak var receiveTokenInput: SendReceiveTokenInput?

    private let sendNotificationManager: SendNotificationManager
    private let expressNotificationManager: ExpressNotificationManager

    init(
        receiveTokenInput: SendReceiveTokenInput?,
        sendNotificationManager: SendNotificationManager,
        expressNotificationManager: ExpressNotificationManager,
    ) {
        self.receiveTokenInput = receiveTokenInput
        self.sendNotificationManager = sendNotificationManager
        self.expressNotificationManager = expressNotificationManager
    }
}

// MARK: - SendAmountNotificationService

extension SendWithSwapNotificationManager: SendAmountNotificationService {
    var notificationMessagePublisher: AnyPublisher<String?, Never> {
        guard let receiveTokenInput else {
            assertionFailure("SendReceiveTokenInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return receiveTokenInput
            .receiveTokenPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { manager, receiveToken -> AnyPublisher<String?, Never> in
                switch receiveToken.value {
                case .none:
                    return .just(output: nil)
                case .some:
                    return manager
                        .expressNotificationManager
                        .notificationPublisher
                        .map { inputs in
                            let suitable = inputs.first { input in
                                switch input.settings.event as? ExpressNotificationEvent {
                                case .tooSmallAmountToSwap, .tooBigAmountToSwap:
                                    return true
                                default:
                                    return false
                                }
                            }

                            return suitable?.settings.event.title?.string
                        }
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendNotificationManager

extension SendWithSwapNotificationManager: SendNotificationManager {
    var notificationInputs: [NotificationViewInput] {
        switch receiveTokenInput?.receiveToken {
        case .none:
            return sendNotificationManager.notificationInputs
        case .some:
            return expressNotificationManager.notificationInputs
        }
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        guard let receiveTokenInput else {
            assertionFailure("SendReceiveTokenInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return receiveTokenInput
            .receiveTokenPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { manager, receiveToken in
                switch receiveToken.value {
                case .none:
                    return manager.sendNotificationManager.notificationPublisher
                case .some:
                    return manager.expressNotificationManager.notificationPublisher
                }
            }
            .eraseToAnyPublisher()
    }

    func setup(input: any SendNotificationManagerInput) {
        sendNotificationManager.setup(input: input)
    }

    func setupManager(with delegate: (any NotificationTapDelegate)?) {
        sendNotificationManager.setupManager(with: delegate)
        expressNotificationManager.setupManager(with: delegate)
    }

    func dismissNotification(with id: NotificationViewId) {
        sendNotificationManager.dismissNotification(with: id)
        expressNotificationManager.dismissNotification(with: id)
    }
}
