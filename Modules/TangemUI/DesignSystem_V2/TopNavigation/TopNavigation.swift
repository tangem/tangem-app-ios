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

        let content: Content
        let accessibilityLabel: String?
        let accessibilityIdentifier: String?
        let action: () -> Void

        public init(
            icon: ImageType,
            accessibilityLabel: String? = nil,
            accessibilityIdentifier: String? = nil,
            action: @escaping () -> Void
        ) {
            content = .icon(icon)
            self.accessibilityLabel = accessibilityLabel
            self.accessibilityIdentifier = accessibilityIdentifier
            self.action = action
        }

        public init(
            title: String,
            accessibilityIdentifier: String? = nil,
            action: @escaping () -> Void
        ) {
            content = .title(title)
            accessibilityLabel = nil
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
        onClose: (() -> Void)? = nil
    ) -> some View {
        modifier(
            TopNavigationModifier(
                contentPosition: contentPosition,
                leading: leading,
                actions: actions,
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
        onClose: (() -> Void)? = nil,
        @ViewBuilder content: () -> Slot
    ) -> some View {
        modifier(
            TopNavigationModifier(
                contentPosition: contentPosition,
                leading: leading,
                actions: actions,
                onClose: onClose,
                slot: content
            )
        )
    }
}
