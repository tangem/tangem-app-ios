//
//  NotificationsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct NotificationsFactory {
    func buildNotificationInputs(
        for events: [WarningEvent],
        action: @escaping NotificationView.NotificationAction,
        buttonAction: @escaping NotificationView.NotificationButtonTapAction,
        dismissAction: @escaping NotificationView.NotificationAction
    ) -> [NotificationViewInput] {
        return events.map { event in
            buildNotificationInput(
                for: event,
                action: action,
                buttonAction: buttonAction,
                dismissAction: dismissAction
            )
        }
    }

    func buildNotificationInput(
        for event: WarningEvent,
        action: @escaping NotificationView.NotificationAction,
        buttonAction: @escaping NotificationView.NotificationButtonTapAction,
        dismissAction: @escaping NotificationView.NotificationAction
    ) -> NotificationViewInput {
        return NotificationViewInput(
            style: event.style(tapAction: action, buttonAction: buttonAction),
            severity: event.severity,
            settings: .init(event: event, dismissAction: dismissAction)
        )
    }

    func buildNotificationInput(
        for event: TokenNotificationEvent,
        buttonAction: NotificationView.NotificationButtonTapAction? = nil,
        dismissAction: NotificationView.NotificationAction? = nil
    ) -> NotificationViewInput {
        return .init(
            style: tokenNotificationStyle(for: event, action: buttonAction),
            severity: event.severity,
            settings: .init(event: event, dismissAction: dismissAction)
        )
    }

    func buildNotificationInput(
        for event: ExpressNotificationEvent,
        buttonAction: NotificationView.NotificationButtonTapAction? = nil
    ) -> NotificationViewInput {
        return .init(
            style: expressNotificationStyle(for: event, action: buttonAction),
            severity: event.severity,
            settings: .init(event: event, dismissAction: nil)
        )
    }

    func buildNotificationInput(
        for event: VisaNotificationEvent
    ) -> NotificationViewInput {
        return .init(
            style: .plain,
            severity: event.severity,
            settings: .init(event: event, dismissAction: nil)
        )
    }

    func buildNotificationInput(
        for event: SendNotificationEvent,
        buttonAction: NotificationView.NotificationButtonTapAction?,
        dismissAction: @escaping NotificationView.NotificationAction
    ) -> NotificationViewInput {
        return .init(
            style: sendNotificationStyle(for: event, action: buttonAction),
            severity: event.severity,
            settings: .init(event: event, dismissAction: dismissAction)
        )
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
            .init(action: action, actionType: actionType, isWithLoader: false),
        ])
    }

    private func expressNotificationStyle(
        for event: ExpressNotificationEvent,
        action: NotificationView.NotificationButtonTapAction?
    ) -> NotificationView.Style {
        guard
            let action,
            let actionType = event.buttonActionType
        else {
            return .plain
        }

        return .withButtons([
            .init(action: action, actionType: actionType, isWithLoader: event.isWithLoader),
        ])
    }

    private func sendNotificationStyle(
        for event: SendNotificationEvent,
        action: NotificationView.NotificationButtonTapAction?
    ) -> NotificationView.Style {
        guard
            let action,
            let actionType = event.buttonActionType
        else {
            return .plain
        }

        return .withButtons([
            .init(action: action, actionType: actionType, isWithLoader: false),
        ])
    }
}
