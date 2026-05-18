//
//  TransferWithSwapNotificationManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import BlockchainSdk

/// A unified notification manager that combines `SendNotificationManager` and `SwapNotificationManager`.
/// Switches between the two based on `TransferWithSwapModelInput.isTransferModePublisher`.
/// Mirror of `SendWithSwapNotificationManager`, but the toggle is source==receive equality
/// rather than receive-token presence.
final class TransferWithSwapNotificationManager {
    private weak var transferWithSwapModelInput: TransferWithSwapModelInput?
    private let sendNotificationManager: SendNotificationManager
    private let swapNotificationManager: SwapNotificationManager

    init(
        transferWithSwapModelInput: TransferWithSwapModelInput,
        sendNotificationManager: SendNotificationManager,
        swapNotificationManager: SwapNotificationManager
    ) {
        self.transferWithSwapModelInput = transferWithSwapModelInput
        self.sendNotificationManager = sendNotificationManager
        self.swapNotificationManager = swapNotificationManager
    }

    deinit {
        AppLogger.debug("TransferWithSwapNotificationManager deinit")
    }
}

// MARK: - SendAmountNotificationService

extension TransferWithSwapNotificationManager: SendAmountNotificationService {
    var notificationMessagePublisher: AnyPublisher<String?, Never> {
        guard let transferWithSwapModelInput else {
            assertionFailure("TransferWithSwapModelInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return transferWithSwapModelInput
            .isTransferModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { manager, isTransfer -> AnyPublisher<String?, Never> in
                if isTransfer {
                    // In transfer mode the SendNotificationManager surfaces in-amount notifications
                    // via its own pipeline; no swap-specific in-line message applies here.
                    return .just(output: nil)
                }
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
            .eraseToAnyPublisher()
    }
}

// MARK: - NotificationManager

extension TransferWithSwapNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        get async {
            if transferWithSwapModelInput?.isTransferMode == true {
                return await sendNotificationManager.notificationInputs
            }

            return await swapNotificationManager.notificationInputs
        }
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        guard let transferWithSwapModelInput else {
            assertionFailure("TransferWithSwapModelInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return transferWithSwapModelInput
            .isTransferModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { manager, isTransfer in
                isTransfer ? manager.sendNotificationManager.notificationPublisher : manager.swapNotificationManager.notificationPublisher
            }
            .eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        sendNotificationManager.setupManager(with: delegate)
        swapNotificationManager.setupManager(with: delegate)
    }

    func dismissNotification(with id: NotificationViewId) {
        sendNotificationManager.dismissNotification(with: id)
        swapNotificationManager.dismissNotification(with: id)
    }
}
