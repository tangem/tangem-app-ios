//
//  NetworkSelectorItemView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct NetworkSelectorItemView: View {
    @ObservedObject var viewModel: NetworkSelectorItemViewModel
    private let style: Style

    init(viewModel: NetworkSelectorItemViewModel, style: Style = .legacy) {
        self.viewModel = viewModel
        self.style = style
    }

    var body: some View {
        Button(action: viewModel.handleTap) {
            HStack(spacing: 8) {
                icon

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(viewModel.networkName.uppercased())
                        .style(Fonts.Bold.subheadline, color: viewModel.networkNameForegroundColor)
                        .lineLimit(2)

                    if let contractName = viewModel.contractName {
                        Text(contractName)
                            .style(Fonts.Regular.caption1, color: viewModel.contractNameForegroundColor)
                            .padding(.leading, 2)
                            .lineLimit(1)
                            .fixedSize()
                    }
                }

                Spacer(minLength: 0)

                if viewModel.isReadonly {
                    addedBadge
                }
            }
            .padding(.vertical, style.verticalPadding)
            .contentShape(.rect)
        }
        .accessibilityIdentifier(TokenAccessibilityIdentifiers.networkCell(for: viewModel.networkName))
        .buttonStyle(.plain)
        .disabled(viewModel.isReadonly)
    }

    private var icon: some View {
        NetworkIcon(
            imageAsset: viewModel.iconImageAsset,
            isActive: true,
            isDisabled: viewModel.isReadonly,
            isMainIndicatorVisible: false,
            showBackground: false,
            size: .init(bothDimensions: style.iconSize)
        )
    }

    @ViewBuilder
    private var addedBadge: some View {
        switch style.addedBadge {
        case .capsuleButton:
            CapsuleButton(title: Localization.commonAdded, action: {})
                .tint(Colors.Control.unchecked)
                .scaleEffect(0.8)
                .disabled(true)
                .accessibilityIdentifier(TokenAccessibilityIdentifiers.networkSwitch(for: viewModel.networkName))

        case .tintedCapsule:
            Text(Localization.commonAdded)
                .style(Fonts.Regular.caption1, color: Color.Tangem.Markers.textGray)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.Tangem.Markers.backgroundTintedGray)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Style

extension NetworkSelectorItemView {
    struct Style {
        let iconSize: CGFloat
        let verticalPadding: CGFloat
        let addedBadge: AddedBadge

        enum AddedBadge {
            case capsuleButton
            case tintedCapsule
        }

        static let legacy = Style(
            iconSize: 22,
            verticalPadding: 16,
            addedBadge: .capsuleButton
        )

        static let addTokenRedesigned = Style(
            iconSize: 36,
            verticalPadding: 14,
            addedBadge: .tintedCapsule
        )
    }
}
