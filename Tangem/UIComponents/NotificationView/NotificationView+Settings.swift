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
        let isLoading: Bool
        let isDisabled: Bool

        init(
            action: @escaping NotificationButtonTapAction,
            actionType: NotificationButtonActionType,
            isWithLoader: Bool,
            isLoading: Bool = false,
            isDisabled: Bool = false
        ) {
            self.action = action
            self.actionType = actionType
            self.isWithLoader = isWithLoader
            self.isLoading = isLoading
            self.isDisabled = isDisabled
        }

        var id: Int { actionType.id }

        static func == (lhs: NotificationButton, rhs: NotificationButton) -> Bool {
            return lhs.actionType.id == rhs.actionType.id
                && lhs.isLoading == rhs.isLoading
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
    }

    enum ColorScheme {
        case primary
        case secondary
        case action
        case critical

        @ViewBuilder
        var background: some View {
            switch self {
            case .critical: DesignSystem.Color.bgStatusErrorSubtle
            case .primary: DesignSystem.Color.bgSecondary
            case .secondary: DesignSystem.Color.bgTransparentPrimary
            case .action: DesignSystem.Color.bgSecondary
            }
        }

        var borderColor: Color? {
            switch self {
            case .secondary: DesignSystem.Color.borderPrimary
            case .primary, .action, .critical: nil
            }
        }

        var dismissButtonColor: Color {
            switch self {
            case .primary, .secondary, .action, .critical:
                return DesignSystem.Color.iconTertiary
            }
        }

        var titleColor: Color {
            switch self {
            case .primary, .secondary, .action, .critical:
                return DesignSystem.Color.textPrimary
            }
        }

        var messageColor: Color {
            switch self {
            case .critical:
                return DesignSystem.Color.textPrimary
            case .primary, .secondary, .action:
                return DesignSystem.Color.textSecondary
            }
        }
    }

    enum ColorTheme {
        case system
        case light
        case dark
    }

    enum LeadingIconType {
        case image(ImageType)
        case icon(TokenIconInfo)
        case loadableIcon(url: URL)
        case progressView
        case placeholder
        case yieldModuleIcon(tokenId: String?)
    }

    struct MessageIcon {
        let iconType: LeadingIconType
        var renderingMode: Image.TemplateRenderingMode?
        var color: Color?
        /// Redesigned banner only: overrides the horizontal icon side (`false` = trailing). Legacy `NotificationView` ignores it.
        var isLeading: Bool?
        var size: CGSize = .init(bothDimensions: 20)
        var yieldModuleIconSize: CGSize = .init(bothDimensions: 12)
    }
}
