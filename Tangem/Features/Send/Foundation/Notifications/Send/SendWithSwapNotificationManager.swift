//
//  SendWithSwapNotificationManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import BlockchainSdk

/// A unified notification manager that combines `SendNotificationManager` and `SwapNotificationManager`.
/// It switches between send and swap modes based on the receive token state,
/// similar to how `SendWithSwapModel` operates.
final class SendWithSwapNotificationManager {
    private weak var receiveTokenInput: SendReceiveTokenInput?

    private let sendNotificationManager: SendNotificationManager
    private let swapNotificationManager: SwapNotificationManager

    init(
        receiveTokenInput: SendReceiveTokenInput?,
        sendNotificationManager: SendNotificationManager,
        swapNotificationManager: SwapNotificationManager
    ) {
        self.receiveTokenInput = receiveTokenInput
        self.sendNotificationManager = sendNotificationManager
        self.swapNotificationManager = swapNotificationManager
    }

    deinit {
        AppLogger.debug("SendWithSwapNotificationManager deinit")
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
                        .swapNotificationManager
                        .notificationPublisher
                        .map { inputs in
                            let suitable = inputs.first { input in
                                switch input.settings.event as? SwapNotificationEvent {
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

// MARK: - SendWithSwapNotificationManager

extension SendWithSwapNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        switch receiveTokenInput?.receiveToken.value {
        case .none:
            return sendNotificationManager.notificationInputs
        case .some:
            return swapNotificationManager.notificationInputs
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
                    return manager.swapNotificationManager.notificationPublisher
                }
            }
            .eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        // Forward delegate to both managers
        sendNotificationManager.setupManager(with: delegate)
        swapNotificationManager.setupManager(with: delegate)
    }

    func dismissNotification(with id: NotificationViewId) {
        // Forward to both managers - whichever is active will handle it
        sendNotificationManager.dismissNotification(with: id)
        swapNotificationManager.dismissNotification(with: id)
    }
}
