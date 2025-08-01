//
//  WCNotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class WCNotificationManager {
    private var feeNotifications: [WCNotificationEvent] = []
    private var simulationNotifications: [WCNotificationEvent] = []
    private let notificationsFactory = NotificationsFactory()

    func updateFeeValidationNotifications(
        _ events: [WCNotificationEvent],
        buttonAction: NotificationView.NotificationButtonTapAction? = nil
    ) -> [NotificationViewInput] {
        feeNotifications = events.filter { $0.notificationType == .feeValidation }
        return feeNotifications.map {
            notificationsFactory.buildNotificationInput(for: $0, buttonAction: buttonAction)
        }
    }

    func updateSimulationValidationNotifications(_ events: [WCNotificationEvent]) -> [NotificationViewInput] {
        simulationNotifications = events.filter { $0.notificationType == .simulationValidation }
        return simulationNotifications.map { notificationsFactory.buildNotificationInput(for: $0) }
    }

    func currentFeeValidationInputs(buttonAction: NotificationView.NotificationButtonTapAction? = nil) -> [NotificationViewInput] {
        feeNotifications.map { notificationsFactory.buildNotificationInput(for: $0, buttonAction: buttonAction) }
    }

    var currentSimulationValidationInputs: [NotificationViewInput] {
        simulationNotifications.map { notificationsFactory.buildNotificationInput(for: $0) }
    }

    func clearAllNotifications() {
        feeNotifications.removeAll()
        simulationNotifications.removeAll()
    }
}
