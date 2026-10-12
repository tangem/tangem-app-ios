//
//  SegmentedControl+Item.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

// MARK: - Item

struct SegmentItemView: View {
    let title: String
    let isSelected: Bool
    let isPillEngaged: Bool
    let height: CGFloat
    let onTap: () -> Void

    var body: some View {
        SwiftUI.Button(action: onTap) {
            SegmentItemLabel(
                title: title,
                isSelected: isSelected,
                isPillEngaged: isPillEngaged,
                height: height
            )
        }
        .buttonStyle(SegmentItemPressStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityShowsLargeContentViewer { Text(title) }
    }
}

// MARK: - Label

private struct SegmentItemLabel: View {
    let title: String
    let isSelected: Bool
    let isPillEngaged: Bool
    let height: CGFloat

    @Environment(\.segmentItemPressed) private var isPressed

    @ScaledMetric private var horizontalPadding: CGFloat = Constants.labelHorizontalPadding

    var body: some View {
        Text(title)
            .style(DesignSystem.Font.subheadingMediumToken, color: titleColor)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, horizontalPadding)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .expandingHitArea(.vertical, by: SegmentedControlMetrics.hitAreaInset)
            .animation(SegmentedControlMetrics.pressAnimation, value: isPressed)
            .animation(SegmentedControlMetrics.labelCrossfade, value: isSelected)
            .animation(SegmentedControlMetrics.labelCrossfade, value: isPillEngaged)
    }

    private var titleColor: Color {
        if isSelected {
            return isPillEngaged ? DesignSystem.Color.textSecondary : DesignSystem.Color.textPrimary
        }

        return isPressed ? DesignSystem.Color.textTertiary : DesignSystem.Color.textSecondary
    }
}

// MARK: - Selection pill

struct SegmentSelectionPill: View {
    let isGlass: Bool

    var body: some View {
        if #available(iOS 26.0, *) {
            ZStack {
                flatFill
                    .opacity(isGlass ? 0 : 1)

                Capsule()
                    .fill(Color.clear)
                    .tangemMaterialSurface(in: Capsule())
                    .opacity(isGlass ? 1 : 0)
            }
        } else {
            flatFill
        }
    }

    private var flatFill: some View {
        Capsule()
            .fill(DesignSystem.Color.bgSpecialControl)
    }
}

// MARK: - Press state

private struct SegmentItemPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .environment(\.segmentItemPressed, configuration.isPressed)
    }
}

private extension EnvironmentValues {
    @Entry var segmentItemPressed = false
}

// MARK: - Constants

private enum Constants {
    static let labelHorizontalPadding: CGFloat = 12
}
