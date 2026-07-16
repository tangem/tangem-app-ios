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
import TangemFoundation

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
    /// The too-small / too-big swap limit is surfaced under the edited amount field by
    /// `SendAmountInteractor` (in that field's currency) and in the notification banner.
    /// Routing it through the amount-field message here as well printed the limit under the
    /// source field even when the limit belonged to the receive side, in the receive currency.
    var notificationMessagePublisher: AnyPublisher<String?, Never> {
        .just(output: nil)
    }
}

// MARK: - SendWithSwapNotificationManager

extension SendWithSwapNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        get async {
            switch receiveTokenInput?.receiveToken.value {
            case .none:
                return await sendNotificationManager.notificationInputs
            case .some:
                return await swapNotificationManager.notificationInputs
            }
        }
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        guard let receiveTokenInput else {
            assertionFailure("SendReceiveTokenInput is not found")
            return .empty
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
