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

struct OnrampOfferView: View {
    let viewModel: OnrampOfferViewModel

    var body: some View {
        VStack(spacing: 12) {
            topView

            Separator(height: .minimal, color: Colors.Stroke.primary)

            bottomView
        }
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 12, horizontalPadding: 14)
    }

    private var topView: some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                title

                amount
            }

            Spacer(minLength: 8)

            CircleButton(title: Localization.commonBuy, action: viewModel.buyButtonAction)
                .size(.medium)
        }
    }

    @ViewBuilder
    private var title: some View {
        switch viewModel.title {
        case .text(let text):
            Text(text)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

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
                .style(Fonts.Bold.callout, color: Colors.Text.primary1)

            switch viewModel.amount.badge {
            case .none:
                EmptyView()

            case .best:
                Assets.Express.bestRateStarIcon.image
                    .resizable()
                    .frame(width: 8, height: 8)
                    .padding(2)
                    .background(Circle().fill(Colors.Icon.accent))

            case .loss(let percent, let signType):
                Text(percent)
                    .style(Fonts.Bold.caption2, color: signType.textColor)
                    .padding(.vertical, 1)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(signType.textColor.opacity(0.1))
                    )
            }
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

            Text(viewModel.provider.name)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        }
    }

    private var trailingBottomView: some View {
        HStack(spacing: 4) {
            Text(Localization.onrampPayWith)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

            viewModel.provider.paymentTypeMethodIcon.image
                .renderingMode(.template)
                .foregroundStyle(Colors.Icon.secondary)
        }
    }
}
