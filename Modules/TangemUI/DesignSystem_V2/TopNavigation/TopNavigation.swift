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
import TangemMacro

public enum TopNavigation {
    public enum ContentPosition: Sendable, Hashable, CaseIterable {
        case start
        case center
    }

    public struct Action {
        @CaseFlagable
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

    @CaseFlagable
    public enum LeadingPolicy {
        /// The back button with the swipe back: the system one on iOS 26+, the DS one below. Use it whenever the screen only needs to go back.
        case automatic
        /// A leading action that isn't a pop, e.g. switching content in place or closing a cover from its stack root.
        /// It replaces the back button, so there is no swipe back. A pop must use `.automatic`, even one that is blocked
        /// while loading (switch to `.none` for that state) or cleans up after itself (do it on disappear).
        case custom(Action)
        /// No leading button — for root screens.
        case none
        /// Non-interactive image, e.g. a logo on a root screen.
        case image(ImageType, height: CGFloat)
    }
}

// MARK: - Convenient defaults

public extension TopNavigation.Action {
    static func back(
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) -> TopNavigation.Action {
        TopNavigation.Action(
            icon: DesignSystem.Icons.ChevronLeft.regular24,
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
            icon: DesignSystem.Icons.Cross.regular24,
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
        close: TopNavigation.Close? = nil
    ) -> some View {
        modifier(
            TopNavigationModifier(
                contentPosition: contentPosition,
                leading: leading,
                actions: actions,
                actionsHaveBackground: actionsHaveBackground,
                close: close
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
        close: TopNavigation.Close? = nil,
        @ViewBuilder content: () -> Slot
    ) -> some View {
        modifier(
            TopNavigationModifier(
                contentPosition: contentPosition,
                leading: leading,
                actions: actions,
                actionsHaveBackground: actionsHaveBackground,
                close: close,
                slot: content
            )
        )
    }

    /// A bar without content of its own — only the chrome: leading button, actions and close.
    func topNavigation(
        contentPosition: TopNavigation.ContentPosition = .center,
        leading: TopNavigation.LeadingPolicy = .automatic,
        actions: TopNavigation.Actions? = nil,
        actionsHaveBackground: Bool = true,
        close: TopNavigation.Close? = nil
    ) -> some View {
        topNavigation(
            contentPosition: contentPosition,
            leading: leading,
            actions: actions,
            actionsHaveBackground: actionsHaveBackground,
            close: close,
            content: { EmptyView() }
        )
    }
}

public extension TopNavigation {
    enum Close {
        case enabled(() -> Void)
        case disabled
    }
}
