//
//  NotificationsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct NotificationsFactory {
    @Injected(\.deprecationService) private var deprecationService: DeprecationServicing
    func buildMissingDerivationNotificationSettings(for numberOfNetworks: Int) -> NotificationView.Settings {
        .init(
            colorScheme: .white,
            icon: .init(image: Assets.blueCircleWarning.image),
            title: Localization.mainWarningMissingDerivationTitle,
            description: Localization.mainWarningMissingDerivationDescription(numberOfNetworks),
            isDismissable: false,
            dismissAction: nil
        )
    }

    func lockedWalletNotificationSettings() -> NotificationView.Settings {
        .init(
            colorScheme: .gray,
            icon: .init(image: Assets.lock.image, color: Colors.Icon.primary1),
            title: Localization.commonUnlockNeeded,
            description: Localization.unlockWalletDescriptionShort(BiometricAuthorizationUtils.biometryType.name),
            isDismissable: false,
            dismissAction: nil
        )
    }

    func missingBackupNotificationSettings() -> NotificationView.Settings {
        .init(
            colorScheme: .white,
            icon: .init(image: Assets.attention.image),
            title: Localization.mainNoBackupWarningTitle,
            description: Localization.mainNoBackupWarningSubtitle,
            isDismissable: false,
            dismissAction: nil
        )
    }

    func buildNotificationInputs(
        for events: [WarningEvent],
        action: @escaping NotificationView.NotificationAction,
        dismissAction: @escaping NotificationView.NotificationAction
    ) -> [NotificationViewInput] {
        return events.map { event in
            buildNotificationInput(for: event, action: action, dismissAction: dismissAction)
        }
    }

    func buildNotificationInput(
        for event: WarningEvent,
        action: @escaping NotificationView.NotificationAction,
        dismissAction: @escaping NotificationView.NotificationAction
    ) -> NotificationViewInput {
        return NotificationViewInput(
            style: notificationStyle(for: event, action: action),
            settings: .init(event: event, dismissAction: dismissAction)
        )
    }

    private func notificationStyle(for event: WarningEvent, action: @escaping NotificationView.NotificationAction) -> NotificationView.Style {
        if event.hasAction {
            return .tappable(action: action)
        } else {
            return .plain
        }
    }
}
