//
//  OnrampOfferView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemAccessibilityIdentifiers

struct OnrampOfferView: View {
    let viewModel: OnrampOfferViewModel

    var body: some View {
        VStack(spacing: 12) {
            topView

            Separator(height: .minimal, color: Colors.Stroke.primary)

            bottomView
        }
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 12, horizontalPadding: 14)
        .opacity(viewModel.isAvailable ? 1 : 0.6)
    }

    private var topView: some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                title

                amount
            }

            Spacer(minLength: 8)

            CapsuleButton(title: Localization.commonBuy, action: viewModel.buyButtonAction)
                .size(.medium)
                .style(.primary)
                .disabled(!viewModel.isAvailable)
        }
    }

    @ViewBuilder
    private var title: some View {
        switch viewModel.title {
        case .text(let text):
            Text(text)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

        case .great:
            Text(Localization.expressProviderGreatRate)
                .style(Fonts.Bold.caption1, color: Colors.Text.accent)

        case .bestRate:
            HStack(alignment: .center, spacing: 4) {
                Assets.Express.bestRateStarIcon16.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.accent)

                Text(Localization.expressProviderBestRate)
                    .style(Fonts.Bold.caption1, color: Colors.Text.accent)
            }

        case .fastest:
            HStack(alignment: .center, spacing: 4) {
                Assets.Express.fastestIcon16.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.attention)

                Text(Localization.onrampOfferTypeFastet)
                    .style(Fonts.Bold.caption1, color: Colors.Text.attention)
            }
        }
    }

    private var amount: some View {
        HStack(spacing: 4) {
            Text(viewModel.amount.formatted)
                .style(
                    Fonts.Bold.callout,
                    color: viewModel.isAvailable ? Colors.Text.primary1 : Colors.Text.tertiary
                )
                .accessibilityIdentifier(OnrampAccessibilityIdentifiers.providerAmount(name: viewModel.provider.name))

            OnrampAmountBadge(badge: viewModel.amount.badge)
        }
    }

    private var bottomView: some View {
        HStack(spacing: .zero) {
            leadingBottomView

            Spacer(minLength: 8)

            trailingBottomView
        }
    }

    private var leadingBottomView: some View {
        HStack(spacing: 4) {
            HStack(spacing: 2) {
                Assets.Express.providerTimeIcon.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.informative)

                Text(viewModel.provider.timeFormatted)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }

            Text(AppConstants.dotSign)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

            Text(Localization.onrampViaProvider(viewModel.provider.name))
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        }
    }

    private var trailingBottomView: some View {
        HStack(spacing: 4) {
            Text(Localization.onrampPayWith)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

            IconView(url: viewModel.provider.paymentType.image, size: .height(16)) {
                SkeletonView()
                    .frame(width: 30, height: 16)
                    .cornerRadiusContinuous(6)
            }
            .foregroundStyle(Colors.Icon.secondary)
        }
    }
}
