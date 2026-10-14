//
//  PolymarketAccountRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAccounts
import TangemAssets
import TangemPolymarketUI
import TangemUI
import TangemUIUtils

struct PolymarketAccountRowView: View {
    @ObservedObject var viewModel: AccountRowButtonViewModel

    @ScaledMetric private var unavailableIconSize: CGFloat = 16
    @ScaledMetric private var scaleFactor: CGFloat = 1

    var body: some View {
        SwiftUI.Button(action: viewModel.onSelect) {
            TangemTwoLineRowLayout(
                icon: { icon },
                primaryLeading: { title },
                secondaryLeading: { subtitle },
                centeredTrailing: {
                    trailing
                        .polymarketStateTransition(viewModel.isBalanceUnavailable)
                }
            )
            .padding(Constants.padding)
            .background(DesignSystem.Color.bgSecondary)
            .cornerRadiusContinuous(Constants.cornerRadius)
        }
        .buttonStyle(.defaultScaled)
        .disabled(viewModel.isDisabled)
        .accessibilityIdentifier(AccountsAccessibilityIdentifiers.walletSettingsAccountRow(accountName: viewModel.name))
    }
}

// MARK: - Subviews

private extension PolymarketAccountRowView {
    var icon: some View {
        AccountIconView(data: viewModel.iconData, settings: AccountItemConstants.collapsedIconSettings)
    }

    var title: some View {
        Text(viewModel.name)
            .style(TangemRowConstants.Style.Title.font, color: TangemRowConstants.Style.Title.color)
            .lineLimit(1)
    }

    @ViewBuilder
    var subtitle: some View {
        switch viewModel.subtitleState {
        case .descriptionOnly(let text), .unavailableWithReason(let text):
            Text(text)
                .style(TangemRowConstants.Style.Subtitle.font, color: TangemRowConstants.Style.Subtitle.color)
                .lineLimit(1)
        case .descriptionWithBalance, .balanceOnly, .none:
            EmptyView()
        }
    }

    @ViewBuilder
    var trailing: some View {
        if viewModel.isBalanceUnavailable {
            Assets.failedCloud.image
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconSecondary)
                .frame(width: unavailableIconSize, height: unavailableIconSize)
        } else if let balance = viewModel.trailingBalanceState {
            LoadableBalanceView(
                state: AttributedBalanceFormatter.decimalColored(
                    balance,
                    integerPart: AttributedBalanceFormatter.PartStyle(font: nil, color: DesignSystem.Color.textPrimary),
                    fractionalPart: AttributedBalanceFormatter.PartStyle(font: nil, color: DesignSystem.Color.textSecondary)
                ),
                style: LoadableBalanceView.Style(
                    font: TangemRowConstants.Style.Title.font,
                    textColor: DesignSystem.Color.textPrimary
                ),
                loader: LoadableBalanceView.LoaderStyle(
                    size: Constants.loaderSize * scaleFactor,
                    cornerRadiusStyle: .capsule
                )
            )
        }
    }
}

// MARK: - Constants

private extension PolymarketAccountRowView {
    enum Constants {
        static let padding: CGFloat = 12
        static let cornerRadius: CGFloat = 24
        static let loaderSize = CGSize(width: 40, height: 12)
    }
}
