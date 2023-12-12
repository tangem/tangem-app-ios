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
    typealias NotificationButtonTapAction = (NotificationViewId, NotificationButtonActionType) -> Void

    struct Settings: Identifiable, Hashable {
        let event: any NotificationEvent
        let dismissAction: NotificationAction?

        var id: NotificationViewId { event.hashValue }

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

        var id: Int { actionType.id }

        static func == (lhs: NotificationButton, rhs: NotificationButton) -> Bool {
            return lhs.actionType == rhs.actionType
        }
    }

    enum Style: Equatable {
        case tappable(action: NotificationAction)
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

    enum ColorScheme {
        case primary
        case secondary
        case swap

        @ViewBuilder
        var color: some View {
            switch self {
            case .primary: Colors.Background.primary
            case .secondary: Colors.Button.disabled
            case .swap:
                Assets.swapBannerBackground.image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }

        var dismissButtonColor: Color {
            switch self {
            case .primary, .secondary:
                return Colors.Icon.inactive
            case .swap:
                return Colors.Text.constantWhite
            }
        }

        var titleColor: Color {
            switch self {
            case .primary, .secondary:
                return Colors.Text.primary1
            case .swap:
                return Colors.Text.constantWhite
            }
        }

        var messageColor: Color {
            switch self {
            case .primary, .secondary:
                return Colors.Text.tertiary
            case .swap:
                return Colors.Text.constantWhite
            }
        }
    }

    enum LeadingIconType {
        case image(Image)
        case progressView
    }

    struct MessageIcon {
        let iconType: LeadingIconType
        var color: Color?
    }
}
