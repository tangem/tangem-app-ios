//
//  TokenDetailsBalanceView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemUI
import TangemUIUtils

struct TokenDetailsBalanceView: View {
    @ObservedObject var viewModel: TokenDetailsBalanceViewModel

    @ScaledMetric private var scaleFactor: CGFloat = 1

    @ScaledMetric private var tokenIconSide: CGFloat = 72
    @ScaledMetric private var balancePickerSide: CGFloat = 20
    @ScaledMetric private var balancePickerSpacing: CGFloat = 4
    @ScaledMetric private var balancePickerTopPadding: CGFloat = 12
    @ScaledMetric private var fiatBalanceTopPadding: CGFloat = 8
    @ScaledMetric private var cryptoBalanceTopPadding: CGFloat = 8

    var body: some View {
        content
            .environment(\.isShimmerActive, true)
    }
}

// MARK: - Subviews

private extension TokenDetailsBalanceView {
    var content: some View {
        VStack(spacing: .zero) {
            tokenIcon

            balancePicker
                .padding(.top, balancePickerTopPadding)

            fiatBalance
                .padding(.top, fiatBalanceTopPadding)

            cryptoBalance
                .padding(.top, cryptoBalanceTopPadding)
        }
    }

    var tokenIcon: some View {
        TokenIcon(tokenIconInfo: viewModel.tokenIconInfo, size: CGSize(width: tokenIconSide, height: tokenIconSide))
            .redesigned()
    }

    var balancePicker: some View {
        HStack(spacing: balancePickerSpacing) {
            Text(viewModel.balanceMode.title)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)

            if viewModel.canChangeBalanceMode {
                Assets.DesignSystem.sort.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
                    .frame(width: balancePickerSide, height: balancePickerSide)
            }
        }
        .contentShape(.rect)
        .onTapGesture(perform: viewModel.onBalancePickerTap)
        .allowsHitTesting(viewModel.canChangeBalanceMode)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(viewModel.canChangeBalanceMode ? .isButton : [])
        .accessibilityIdentifier(TokenAccessibilityIdentifiers.balanceModePicker)
    }

    var fiatBalance: some View {
        TokenDetailsBalanceStateView(
            state: viewModel.fiatBalanceState,
            skeletonSize: CGSize(width: 243, height: 48) * scaleFactor,
            minimumScaleFactor: Constants.fiatBalanceMinimumScaleFactor
        )
        .accessibilityIdentifier(fiatBalanceAccessibilityIdentifier)
    }

    var fiatBalanceAccessibilityIdentifier: String {
        switch viewModel.balanceMode {
        case .total:
            return TokenAccessibilityIdentifiers.totalBalance
        case .available:
            return TokenAccessibilityIdentifiers.availableBalance
        }
    }

    var cryptoBalance: some View {
        TokenDetailsBalanceStateView(
            state: viewModel.cryptoBalanceState,
            skeletonSize: CGSize(width: 115, height: 24) * scaleFactor
        )
    }
}

// MARK: - Constants

private extension TokenDetailsBalanceView {
    enum Constants {
        static let fiatBalanceMinimumScaleFactor = 15.0 / 44.0
    }
}
