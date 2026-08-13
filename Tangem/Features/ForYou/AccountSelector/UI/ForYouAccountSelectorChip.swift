//
//  ForYouAccountSelectorChip.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

/// Local stand-in for the DS "Filter" chip until it's ported to TangemUI.
struct ForYouAccountSelectorChip: View {
    enum SelectionState: Equatable {
        case all
        case single(name: String)
        case multiple(count: Int)
    }

    let selection: SelectionState
    let onOpen: () -> Void
    let onReset: () -> Void

    @ScaledMetric private var iconSize: CGFloat = 16
    @ScaledMetric private var leadingPadding: CGFloat = 12
    @ScaledMetric private var trailingPadding: CGFloat = 10
    @ScaledMetric private var verticalPadding: CGFloat = 8
    @ScaledMetric private var height: CGFloat = 36

    var body: some View {
        switch selection {
        case .all:
            defaultChip
        case .single(let name):
            selectedChip { singleLabel(name: name) }
        case .multiple(let count):
            selectedChip { multipleLabel(count: count) }
        }
    }
}

private extension ForYouAccountSelectorChip {
    var defaultChip: some View {
        Button(action: onOpen) {
            pill(fill: DesignSystem.Color.bgOpaquePrimary, hasShadow: false) {
                HStack(spacing: Constants.spacing) {
                    Text(Localization.commonAllAccounts)
                        .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)

                    icon(DesignSystem.Icons.ChevronDown.regular16, color: DesignSystem.Color.iconSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    func selectedChip(@ViewBuilder label: () -> some View) -> some View {
        pill(fill: DesignSystem.Color.bgInverse, hasShadow: true) {
            HStack(spacing: Constants.spacing) {
                label()

                icon(DesignSystem.Icons.Cross.regular16, color: DesignSystem.Color.textInverseSecondary)
            }
        }
        .contentShape(Capsule())
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onOpen() }
        .accessibilityAction(named: Text(Localization.commonReset)) { onReset() }
        .overlay(alignment: .trailing) {
            // The whole pill opens the selector; this trailing region alone resets, giving the ✕ a real hit area.
            Button(action: onReset) {
                Color.clear
                    .frame(width: iconSize + trailingPadding + Constants.spacing)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(Localization.commonReset))
        }
    }

    func singleLabel(name: String) -> some View {
        Text(name)
            .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textInversePrimary)
    }

    func multipleLabel(count: Int) -> some View {
        HStack(spacing: Constants.countSpacing) {
            Text(Localization.commonAccounts)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textInversePrimary)

            Text("+\(count)")
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textInverseSecondary)
        }
    }

    func pill(fill: Color, hasShadow: Bool, @ViewBuilder content: () -> some View) -> some View {
        content()
            .lineLimit(1)
            .padding(.leading, leadingPadding)
            .padding(.trailing, trailingPadding)
            .padding(.vertical, verticalPadding)
            .frame(minHeight: height)
            .background {
                Capsule()
                    .fill(fill)
                    .shadow(
                        color: hasShadow ? Constants.shadow.color : .clear,
                        radius: hasShadow ? Constants.shadow.blur / 2 : 0,
                        y: hasShadow ? Constants.shadow.offsetY : 0
                    )
            }
    }

    func icon(_ image: ImageType, color: Color) -> some View {
        image.image
            .renderingMode(.template)
            .resizable()
            .frame(size: CGSize(bothDimensions: iconSize))
            .foregroundStyle(color)
    }
}

private extension ForYouAccountSelectorChip {
    enum Constants {
        static let spacing: CGFloat = 6
        static let countSpacing: CGFloat = 2
        /// DS "Filter" shadow, applied by hand: `tangemShadow` maps figma blur straight to radius (needs blur / 2).
        static let shadow = DesignSystem.Shadow.button
    }
}

// MARK: - ForYouAccountSelectorChipView

struct ForYouAccountSelectorChipView: View {
    @ObservedObject var viewModel: ForYouAccountSelectorChipViewModel

    var body: some View {
        ForYouAccountSelectorChip(
            selection: viewModel.selection,
            onOpen: viewModel.openAccountSelector,
            onReset: viewModel.resetSelection
        )
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 16) {
        ForYouAccountSelectorChip(selection: .all, onOpen: {}, onReset: {})
        ForYouAccountSelectorChip(selection: .single(name: "Family account"), onOpen: {}, onReset: {})
        ForYouAccountSelectorChip(selection: .multiple(count: 3), onOpen: {}, onReset: {})
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Color.bgSecondary.ignoresSafeArea())
}
