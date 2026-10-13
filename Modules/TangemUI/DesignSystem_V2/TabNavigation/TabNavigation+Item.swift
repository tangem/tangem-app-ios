//
//  TabNavigation+Item.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

// MARK: - Item

struct TabItemView<Item: TabNavigationItem>: View {
    let item: Item
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        SwiftUI.Button(action: onTap) {
            TabItemLabel(item: item, isSelected: isSelected)
        }
        .buttonStyle(TabItemPressStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Label

private struct TabItemLabel<Item: TabNavigationItem>: View {
    let item: Item
    let isSelected: Bool

    @Environment(\.tabItemPressed) private var isPressed

    @ScaledMetric private var iconSize: CGFloat = Constants.iconSize
    @ScaledMetric private var padding: CGFloat = Constants.labelPadding
    @ScaledMetric private var innerSpacing: CGFloat = Constants.innerSpacing

    var body: some View {
        HStack(spacing: innerSpacing) {
            if let icon = item.icon {
                icon.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: iconSize, height: iconSize)
                    .foregroundStyle(iconColor)
                    .accessibilityHidden(true)
            }

            HStack(spacing: innerSpacing) {
                Text(item.title)
                    .font(token: DesignSystem.Font.subheadingMediumToken)
                    .foregroundStyle(titleColor)
                    .lineLimit(1)

                if let counter = item.counter {
                    Text(counter)
                        .font(token: DesignSystem.Font.subheadingMediumToken)
                        .foregroundStyle(DesignSystem.Color.textTertiary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, innerSpacing)
            .accessibilityElement(children: .combine)
        }
        .padding(padding)
        .frame(minWidth: Constants.minWidth)
        .expandingHitArea(.vertical, by: Constants.hitAreaInset)
        .animation(Constants.pressAnimation, value: isPressed)
    }

    private var titleColor: Color {
        if isPressed { return DesignSystem.Color.textTertiary }
        return isSelected ? DesignSystem.Color.textPrimary : DesignSystem.Color.textSecondary
    }

    private var iconColor: Color {
        if isPressed { return DesignSystem.Color.iconTertiary }
        return isSelected ? DesignSystem.Color.iconPrimary : DesignSystem.Color.iconSecondary
    }
}

// MARK: - Selection pill

struct TabSelectionPill: View {
    let variant: TabNavigationVariant

    var body: some View {
        switch variant {
        case .material:
            Color.clear
                .tangemMaterialSurface(in: Capsule())
        case .transparent:
            Capsule().fill(DesignSystem.Color.bgTransparentSecondary)
        }
    }
}

// MARK: - Press state

private struct TabItemPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .environment(\.tabItemPressed, configuration.isPressed)
    }
}

private struct TabItemPressedKey: EnvironmentKey {
    static let defaultValue = false
}

private extension EnvironmentValues {
    var tabItemPressed: Bool {
        get { self[TabItemPressedKey.self] }
        set { self[TabItemPressedKey.self] = newValue }
    }
}

// MARK: - Loading placeholder

struct TabItemPlaceholder: View {
    @ScaledMetric private var height: CGFloat = Constants.placeholderHeight

    var body: some View {
        Capsule()
            .fill(DesignSystem.Color.bgTransparentSecondary)
            .frame(width: Constants.placeholderWidth, height: height)
            .shimmering()
    }
}

// MARK: - Constants

private enum Constants {
    static let iconSize: CGFloat = 20
    static let labelPadding: CGFloat = 8
    static let innerSpacing: CGFloat = 4
    static let minWidth: CGFloat = 56
    static let hitAreaInset: CGFloat = 4
    static let pressAnimation: Animation = .timingCurve(0.8, 0, 0.6, 1, duration: 0.2)

    static let placeholderHeight: CGFloat = 36
    static let placeholderWidth: CGFloat = 72
}
