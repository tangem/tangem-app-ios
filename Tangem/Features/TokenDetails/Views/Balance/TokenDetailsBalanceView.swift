//
//  TokenDetailsBalanceView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct TokenDetailsBalanceView: View {
    @ObservedObject var viewModel: TokenDetailsBalanceViewModel

    @ScaledSize private var tokenIconSize = CGSize(bothDimensions: .unit(.x18))
    @ScaledSize private var balancePickerSize = CGSize(bothDimensions: .unit(.x5))
    @ScaledSize private var fiatBalanceSkeletonSize = CGSize(width: 243, height: 48)
    @ScaledSize private var cryptoBalanceSkeletonSize = CGSize(width: 115, height: 24)
    @ScaledMetric private var balancePickerSpacing: CGFloat = .unit(.x1)
    @ScaledMetric private var balancePickerTopPadding: CGFloat = .unit(.x3)
    @ScaledMetric private var fiatBalanceTopPadding: CGFloat = .unit(.x2)
    @ScaledMetric private var cryptoBalanceTopPadding: CGFloat = .unit(.x2)

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
        TokenIcon(
            tokenIconInfo: viewModel.tokenIconInfo,
            size: tokenIconSize
        )
    }

    var balancePicker: some View {
        HStack(spacing: balancePickerSpacing) {
            Text(viewModel.balanceMode.title)
                .style(.Tangem.Subheadline.medium, color: .Tangem.Text.Neutral.primary)

            if viewModel.canChangeBalanceMode {
                Assets.DesignSystem.sort.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.Tangem.Graphic.Neutral.secondary)
                    .frame(size: balancePickerSize)
            }
        }
        .contentShape(.rect)
        .onTapGesture(perform: viewModel.onBalancePickerTap)
        .allowsHitTesting(viewModel.canChangeBalanceMode)
    }

    var fiatBalance: some View {
        balanceState(viewModel.fiatBalanceState, skeletonSize: fiatBalanceSkeletonSize)
    }

    var cryptoBalance: some View {
        balanceState(viewModel.cryptoBalanceState, skeletonSize: cryptoBalanceSkeletonSize)
    }

    func balanceState(_ state: TokenDetailsBalanceState, skeletonSize: CGSize) -> some View {
        TokenDetailsBalanceStateView(
            state: state,
            skeletonSize: skeletonSize
        )
    }
}
