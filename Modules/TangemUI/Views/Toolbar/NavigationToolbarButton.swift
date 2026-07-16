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
    let sfSymbol: String
    let iconAsset: ImageType
    let placement: ToolbarItemPlacement
    var isRedesign: Bool
    var accessibilityIdentifier: String?
    var accessibilityLabel: String?
    let action: () -> Void

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
        isRedesign: Bool = false,
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) {
        self.sfSymbol = sfSymbol
        self.iconAsset = iconAsset
        self.placement = placement
        self.isRedesign = isRedesign
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
    }

    public var body: some CustomizableToolbarContent {
        ToolbarItem(id: sfSymbol, placement: placement) {
            toolbarButton
                .accessibilityLabel(accessibilityLabel)
                .accessibilityIdentifier(accessibilityIdentifier)
        }
    }

    @ViewBuilder
    private var toolbarButton: some View {
        if isRedesign || isLiquidGlassSupported {
            systemLabelButton
        } else {
            circleIconButton
        }
    }

    private var systemLabelButton: some View {
        Button("", systemImage: sfSymbol, action: action)
            .labelStyle(.iconOnly)
            .tint(Color.Tangem.Graphic.Neutral.primary)
            .foregroundStyle(Color.Tangem.Graphic.Neutral.primary)
            .frame(width: 44, height: 44)
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

public extension NavigationToolbarButton {
    func accessibilityIdentifier(_ identifier: String) -> Self {
        var mutableCopy = self
        mutableCopy.accessibilityIdentifier = identifier
        return mutableCopy
    }

    func accessibilityLabel(_ label: String) -> Self {
        var mutableCopy = self
        mutableCopy.accessibilityLabel = label
        return mutableCopy
    }

    func redesigned() -> Self {
        var mutableCopy = self
        mutableCopy.isRedesign = true
        return mutableCopy
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

    static func add(placement: ToolbarItemPlacement, action: @escaping () -> Void) -> NavigationToolbarButton {
        navigationToolbarButton(for: .add, placement: placement, action: action)
    }

    static func share(placement: ToolbarItemPlacement, action: @escaping () -> Void) -> NavigationToolbarButton {
        navigationToolbarButton(for: .share, placement: placement, action: action)
    }

    static func details(placement: ToolbarItemPlacement, action: @escaping () -> Void) -> NavigationToolbarButton {
        navigationToolbarButton(for: .details, placement: placement, action: action)
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
