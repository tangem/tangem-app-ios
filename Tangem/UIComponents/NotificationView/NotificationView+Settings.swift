//
//  NotificationView+Settings.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

extension NotificationView {
    typealias NotificationAction = (NotificationViewId) -> Void
    struct Settings: Identifiable, Hashable {
        let id: NotificationViewId = UUID().uuidString
        let colorScheme: NotificationView.ColorScheme
        let icon: NotificationView.MessageIcon
        let title: String
        let description: String?
        let event: WarningEvent?
        let isDismissable: Bool
        let dismissAction: NotificationAction?

        init(
            colorScheme: NotificationView.ColorScheme,
            icon: NotificationView.MessageIcon,
            title: String,
            description: String? = nil,
            isDismissable: Bool,
            dismissAction: NotificationView.NotificationAction? = nil
        ) {
            self.colorScheme = colorScheme
            self.icon = icon
            self.title = title
            self.description = description
            event = nil
            self.isDismissable = isDismissable
            self.dismissAction = dismissAction
        }

        init(event: WarningEvent, dismissAction: NotificationAction?) {
            self.event = event
            colorScheme = event.colorScheme
            icon = event.icon
            title = event.title
            description = event.description
            isDismissable = event.isDismissable
            self.dismissAction = dismissAction
        }

        static func == (lhs: Settings, rhs: Settings) -> Bool {
            return lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    enum Style: Equatable {
        case tappable(action: NotificationAction)
        case withButtons([MainButton.Settings])
        case plain

        static func == (lhs: NotificationView.Style, rhs: NotificationView.Style) -> Bool {
            switch (lhs, rhs) {
            case (.tappable, .tappable): return true
            case (.plain, .plain): return true
            case (.withButtons(let lhsButtons), .withButtons(let rhsButtons)):
                return lhsButtons == rhsButtons
            default: return false
            }
        }
    }

    enum ColorScheme {
        case white
        case gray

        var color: Color {
            switch self {
            case .white: return Colors.Background.primary
            case .gray: return Colors.Button.disabled
            }
        }
    }

    struct MessageIcon {
        let image: Image
        var color: Color?
    }
}
