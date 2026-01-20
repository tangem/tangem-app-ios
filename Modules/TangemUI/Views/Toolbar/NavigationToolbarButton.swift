//
//  NavigationToolbarButton.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization

/// A toolbar button used as a replacement for a system navigation toolbar button.
///
/// On iOS 26, it matches look and feel of system ``NavigationStack`` back / close toolbar buttons.
///
/// On earlier iOS versions, an icon with a round background is used.
/// - SeeAlso: ``NavigationBarButton`` when you need a button outside of ``View.toolbar(content:)``.
public struct NavigationToolbarButton: CustomizableToolbarContent {
    private let sfSymbol: String
    private let iconAsset: ImageType
    private let placement: ToolbarItemPlacement
    private let accessibilityIdentifier: String?
    private let action: () -> Void

    /// Creates a navigation toolbar button.
    /// - Parameters:
    ///   - sfSymbol: The name of the system symbol image. Use the SF Symbols app to look up the names of system symbol images.
    ///   - iconAsset: The icon used for 18 and older iOS versions.
    ///   - placement: Which section of the toolbar the button should be placed in.
    ///   - action: The action to perform when the user triggers the button.
    init(
        sfSymbol: String,
        iconAsset: ImageType,
        placement: ToolbarItemPlacement,
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) {
        self.sfSymbol = sfSymbol
        self.iconAsset = iconAsset
        self.placement = placement
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
    }

    public var body: some CustomizableToolbarContent {
        ToolbarItem(id: sfSymbol, placement: placement) {
            toolbarButton
                .accessibilityIdentifier(accessibilityIdentifier)
        }
    }

    @ViewBuilder
    private var toolbarButton: some View {
        if #available(iOS 26.0, *) {
            systemLabelButton
        } else {
            circleIconButton
        }
    }

    @available(iOS 26.0, *)
    private var systemLabelButton: some View {
        Button(action: action) {
            Image(systemName: sfSymbol)
                .foregroundStyle(Colors.Text.primary1)
                .fontWeight(.semibold)
        }
    }

    private var circleIconButton: some View {
        Button(action: action) {
            iconAsset.image
                .resizable()
                .renderingMode(.template)
                .frame(width: 20, height: 20)
                .foregroundStyle(Colors.Icon.informative)
                .padding(4)
                .background {
                    Circle()
                        .fill(Colors.Button.secondary)
                }
                .contentShape(.rect)
        }
    }
}

// MARK: - Factory methods

public extension NavigationToolbarButton {
    static func back(placement: ToolbarItemPlacement, action: @escaping () -> Void) -> NavigationToolbarButton {
        navigationToolbarButton(for: .back, placement: placement, action: action)
    }

    static func close(placement: ToolbarItemPlacement, action: @escaping () -> Void) -> NavigationToolbarButton {
        navigationToolbarButton(for: .close, placement: placement, action: action)
    }

    private static func navigationToolbarButton(
        for role: NavigationBarButtonRole,
        placement: ToolbarItemPlacement,
        action: @escaping () -> Void
    ) -> NavigationToolbarButton {
        NavigationToolbarButton(
            sfSymbol: role.sfSymbol,
            iconAsset: role.iconAsset,
            placement: placement,
            accessibilityIdentifier: role.accessibilityIdentifier,
            action: action
        )
    }
}
