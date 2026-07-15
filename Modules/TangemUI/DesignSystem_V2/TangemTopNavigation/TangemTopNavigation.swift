//
//  TangemTopNavigation.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

public enum TangemTopNavigation {
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
}

// MARK: - Convenient defaults

public extension TangemTopNavigation.Action {
    static func back(
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) -> TangemTopNavigation.Action {
        TangemTopNavigation.Action(
            icon: DesignSystem.Icons.ChevronLeft.regular20,
            accessibilityLabel: Localization.commonBack,
            accessibilityIdentifier: accessibilityIdentifier,
            action: action
        )
    }

    static func close(
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) -> TangemTopNavigation.Action {
        TangemTopNavigation.Action(
            icon: DesignSystem.Icons.Cross.regular20,
            accessibilityLabel: Localization.commonClose,
            accessibilityIdentifier: accessibilityIdentifier,
            action: action
        )
    }
}

public extension View {
    func tangemTopNavigation(
        title: String,
        subtitle: String? = nil,
        animatesSubtitleAppearance: Bool = true,
        contentPosition: TangemTopNavigation.ContentPosition = .center,
        leading: TangemTopNavigation.Action? = nil,
        actions: [TangemTopNavigation.Action] = [],
        onClose: (() -> Void)? = nil
    ) -> some View {
        modifier(
            TangemTopNavigationModifier(
                contentPosition: contentPosition,
                leading: leading,
                actions: actions,
                onClose: onClose
            ) {
                TangemTopNavigationTitleContent(
                    title: title,
                    subtitle: subtitle,
                    animatesSubtitleAppearance: animatesSubtitleAppearance
                )
            }
        )
    }

    func tangemTopNavigation<Slot: View>(
        contentPosition: TangemTopNavigation.ContentPosition = .center,
        leading: TangemTopNavigation.Action? = nil,
        actions: [TangemTopNavigation.Action] = [],
        onClose: (() -> Void)? = nil,
        @ViewBuilder content: () -> Slot
    ) -> some View {
        modifier(
            TangemTopNavigationModifier(
                contentPosition: contentPosition,
                leading: leading,
                actions: actions,
                onClose: onClose,
                slot: content
            )
        )
    }
}
