//
//  NotificationsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct NotificationsFactory {
    func buildMissingDerivationNotificationSettings(for numberOfNetworks: Int) -> NotificationView.Settings {
        .init(event: WarningEvent.missingDerivation(numberOfNetworks: numberOfNetworks), dismissAction: nil)
    }

    func lockedWalletNotificationSettings() -> NotificationView.Settings {
        .init(event: WarningEvent.walletLocked, dismissAction: nil)
    }

    func missingBackupNotificationSettings() -> NotificationView.Settings {
        .init(event: WarningEvent.missingBackup, dismissAction: nil)
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

    func buildNotificationInput(
        for tokenEvent: TokenNotificationEvent,
        buttonAction: NotificationView.NotificationButtonTapAction? = nil,
        dismissAction: NotificationView.NotificationAction? = nil
    ) -> NotificationViewInput {
        return .init(
            style: tokenNotificationStyle(for: tokenEvent, action: buttonAction),
            settings: .init(event: tokenEvent, dismissAction: dismissAction)
        )
    }

    private func notificationStyle(for event: WarningEvent, action: @escaping NotificationView.NotificationAction) -> NotificationView.Style {
        if event.hasAction {
            return .tappable(action: action)
        } else {
            return .plain
        }
    }

    private func tokenNotificationStyle(
        for event: TokenNotificationEvent,
        action: NotificationView.NotificationButtonTapAction?
    ) -> NotificationView.Style {
        guard
            let action,
            let actionType = event.buttonAction
        else {
            return .plain
        }

        return .withButtons([
            .init(action: action, actionType: actionType),
        ])
    }
}
