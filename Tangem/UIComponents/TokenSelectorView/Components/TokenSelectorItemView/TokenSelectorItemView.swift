//
//  TokenSelectorItemView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemAccessibilityIdentifiers

struct TokenSelectorItemView: View {
    @ObservedObject var viewModel: TokenSelectorItemViewModel

    private var backgroundColor: Color {
        return DesignSystem.Color.bgSecondary
    }

    var body: some View {
        SwiftUI.Button(action: { viewModel.action(viewModel.availabilityType) }) {
            TwoLineRowWithIcon(
                icon: {
                    TokenItemViewLeadingComponent(
                        tokenIconInfo: viewModel.tokenIconInfo,
                        hasMonochromeIcon: viewModel.availabilityType.isUnavailable
                    )
                },
                primaryLeadingView: {
                    Text(viewModel.name)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                        .lineLimit(1)
                },
                primaryTrailingView: { primaryTrailingView },
                secondaryLeadingView: { secondaryLeadingView },
                secondaryTrailingView: { secondaryTrailingView }
            )
            .padding(.vertical, 14)
        }
        .disabled(viewModel.availabilityType.disablesTap)
        .background(backgroundColor)
        .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.tokenSelectorItem(name: viewModel.name))
    }

    @ViewBuilder
    private var primaryTrailingView: some View {
        switch viewModel.availabilityType {
        case .available:
            LoadableBalanceView(
                state: viewModel.fiatBalance,
                style: .init(font: DesignSystem.Font.bodyMediumToken, textColor: DesignSystem.Color.textPrimary),
                loader: .init(size: .init(width: 40, height: 12))
            )
            .layoutPriority(3)
        case .unavailable:
            EmptyView()
        }
    }

    @ViewBuilder
    private var secondaryTrailingView: some View {
        switch viewModel.availabilityType {
        case .available:
            LoadableBalanceView(
                state: viewModel.cryptoBalance,
                style: .init(font: DesignSystem.Font.captionMediumToken, textColor: DesignSystem.Color.textSecondary),
                loader: .init(size: .init(width: 40, height: 12))
            )
            .layoutPriority(3)
        case .unavailable:
            EmptyView()
        }
    }

    private var secondaryLeadingView: some View {
        Text(viewModel.secondaryLeadingText)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .lineLimit(1)
    }
}
