//
//  NotificationView+Settings.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

extension NotificationView {
    typealias NotificationAction = (NotificationViewId) -> Void
    typealias NotificationButtonTapAction = (NotificationViewId, NotificationButtonActionType) -> Void

    /// Currently, this property isn't used in any way in the UI and acts more like a semantic attribute of the notification.
    /// - Note: Ideally should mimic standard UNIX syslog severity levels https://en.wikipedia.org/wiki/Syslog
    enum Severity {
        case info
        case warning
        case critical
    }

    struct Settings: Identifiable, Hashable {
        let event: any NotificationEvent
        let dismissAction: NotificationAction?

        var id: NotificationViewId { event.id }

        static func == (lhs: Settings, rhs: Settings) -> Bool {
            return lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    struct NotificationButton: Identifiable, Equatable {
        let action: NotificationButtonTapAction
        let actionType: NotificationButtonActionType
        let isWithLoader: Bool
        let isDisabled: Bool

        init(
            action: @escaping NotificationButtonTapAction,
            actionType: NotificationButtonActionType,
            isWithLoader: Bool,
            isDisabled: Bool = false
        ) {
            self.action = action
            self.actionType = actionType
            self.isWithLoader = isWithLoader
            self.isDisabled = isDisabled
        }

        var id: Int { actionType.id }

        static func == (lhs: NotificationButton, rhs: NotificationButton) -> Bool {
            return lhs.actionType.id == rhs.actionType.id
        }
    }

    enum Style: Equatable {
        case tappable(hasChevron: Bool, action: NotificationAction)
        case withButtons([NotificationButton])
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

    enum Title: Hashable {
        case string(String)
        case attributed(AttributedString)

        var string: String? {
            switch self {
            case .string(let value): value
            case .attributed: nil
            }
        }
    }

    enum ColorScheme {
        case primary
        case secondary
        case action
        /// Temporary: added for the Black Friday promo banner (Nov 2025).
        /// Remove if no longer used.
        case tertiary

        @ViewBuilder
        var background: some View {
            switch self {
            case .primary, .tertiary: Colors.Background.primary
            case .secondary: Colors.Button.disabled
            case .action: Colors.Background.action
            }
        }

        var dismissButtonColor: Color {
            switch self {
            case .primary, .secondary, .action, .tertiary:
                return Colors.Icon.inactive
            }
        }

        var titleColor: Color {
            switch self {
            case .primary, .secondary, .action, .tertiary:
                return Colors.Text.primary1
            }
        }

        var messageColor: Color {
            switch self {
            case .primary, .secondary, .action:
                return Colors.Text.tertiary
            case .tertiary:
                return Colors.Text.secondary
            }
        }
    }

    enum LeadingIconType {
        case image(Image)
        case icon(TokenIconInfo)
        case progressView
        case placeholder
        case yieldModuleIcon(tokenId: String?)
    }

    struct MessageIcon {
        let iconType: LeadingIconType
        var color: Color?
        var size: CGSize = .init(bothDimensions: 20)
        var yieldModuleIconSize: CGSize = .init(bothDimensions: 12)
    }
}
