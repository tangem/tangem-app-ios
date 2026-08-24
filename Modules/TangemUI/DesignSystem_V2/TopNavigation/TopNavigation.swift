//
//  TopNavigation.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

public enum TopNavigation {
    public enum ContentPosition: Sendable, Hashable, CaseIterable {
        case start
        case center
    }

    public struct Action {
        enum Content {
            case icon(ImageType)
            case title(String)
        }

        enum Trigger {
            case perform(_ action: () -> Void)
            case menu(_ items: [MenuItem])
        }

        let content: Content
        let accessibilityLabel: String?
        let accessibilityIdentifier: String?
        let trigger: Trigger

        public init(
            icon: ImageType,
            accessibilityLabel: String? = nil,
            accessibilityIdentifier: String? = nil,
            action: @escaping () -> Void
        ) {
            content = .icon(icon)
            self.accessibilityLabel = accessibilityLabel
            self.accessibilityIdentifier = accessibilityIdentifier
            trigger = .perform(action)
        }

        public init(
            title: String,
            accessibilityIdentifier: String? = nil,
            action: @escaping () -> Void
        ) {
            content = .title(title)
            accessibilityLabel = nil
            self.accessibilityIdentifier = accessibilityIdentifier
            trigger = .perform(action)
        }

        /// A tap opens a menu of the given items instead of firing an action of its own.
        public init(
            icon: ImageType,
            accessibilityLabel: String? = nil,
            accessibilityIdentifier: String? = nil,
            menu: [MenuItem]
        ) {
            content = .icon(icon)
            self.accessibilityLabel = accessibilityLabel
            self.accessibilityIdentifier = accessibilityIdentifier
            trigger = .menu(menu)
        }
    }

    public struct MenuItem {
        let title: String
        let role: ButtonRole?
        let accessibilityIdentifier: String?
        let action: () -> Void

        public init(
            title: String,
            role: ButtonRole? = nil,
            accessibilityIdentifier: String? = nil,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.role = role
            self.accessibilityIdentifier = accessibilityIdentifier
            self.action = action
        }
    }

    public enum Actions {
        case one(Action)
        case two(Action, Action)
        case three(Action, Action, Action)

        var values: [Action] {
            switch self {
            case .one(let first): [first]
            case .two(let first, let second): [first, second]
            case .three(let first, let second, let third): [first, second, third]
            }
        }
    }

    public enum LeadingPolicy {
        /// Default DS back button that calls the environment `dismiss`.
        case automatic
        /// Explicit leading action.
        case custom(Action)
        /// No leading button — for root screens.
        case none
    }
}

// MARK: - Convenient defaults

public extension TopNavigation.Action {
    static func back(
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) -> TopNavigation.Action {
        TopNavigation.Action(
            icon: DesignSystem.Icons.ChevronLeft.regular20,
            accessibilityLabel: Localization.commonBack,
            accessibilityIdentifier: accessibilityIdentifier,
            action: action
        )
    }

    static func close(
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) -> TopNavigation.Action {
        TopNavigation.Action(
            icon: DesignSystem.Icons.Cross.regular20,
            accessibilityLabel: Localization.commonClose,
            accessibilityIdentifier: accessibilityIdentifier,
            action: action
        )
    }
}

public extension View {
    func topNavigation(
        title: String,
        subtitle: String? = nil,
        animatesSubtitleAppearance: Bool = true,
        contentPosition: TopNavigation.ContentPosition = .center,
        leading: TopNavigation.LeadingPolicy = .automatic,
        actions: TopNavigation.Actions? = nil,
        actionsHaveBackground: Bool = true,
        onClose: (() -> Void)? = nil
    ) -> some View {
        modifier(
            TopNavigationModifier(
                contentPosition: contentPosition,
                leading: leading,
                actions: actions,
                actionsHaveBackground: actionsHaveBackground,
                onClose: onClose
            ) {
                TopNavigationTitleContent(
                    title: title,
                    subtitle: subtitle,
                    animatesSubtitleAppearance: animatesSubtitleAppearance
                )
            }
        )
    }

    func topNavigation<Slot: View>(
        contentPosition: TopNavigation.ContentPosition = .center,
        leading: TopNavigation.LeadingPolicy = .automatic,
        actions: TopNavigation.Actions? = nil,
        actionsHaveBackground: Bool = true,
        onClose: (() -> Void)? = nil,
        @ViewBuilder content: () -> Slot
    ) -> some View {
        modifier(
            TopNavigationModifier(
                contentPosition: contentPosition,
                leading: leading,
                actions: actions,
                actionsHaveBackground: actionsHaveBackground,
                onClose: onClose,
                slot: content
            )
        )
    }

    /// A bar without content of its own — only the chrome: leading button, actions and close.
    /// - Note: A separate overload rather than a `content:` default, since a default makes the trailing-closure
    /// scan bind a slot-only call's closure to `onClose:` instead of the slot.
    func topNavigation(
        contentPosition: TopNavigation.ContentPosition = .center,
        leading: TopNavigation.LeadingPolicy = .automatic,
        actions: TopNavigation.Actions? = nil,
        actionsHaveBackground: Bool = true,
        onClose: (() -> Void)? = nil
    ) -> some View {
        topNavigation(
            contentPosition: contentPosition,
            leading: leading,
            actions: actions,
            actionsHaveBackground: actionsHaveBackground,
            onClose: onClose,
            content: { EmptyView() }
        )
    }
}
