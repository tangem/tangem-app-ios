//
//  TangemPayOfferView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct TangemPayOfferView: View {
    @ObservedObject var viewModel: TangemPayOfferViewModel

    var body: some View {
        GeometryReader { proxy in
            content(screenWidth: proxy.size.width)
        }
    }

    private func content(screenWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    Assets.Visa.card.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: screenWidth * 0.5)

                    titleSection
                        .padding(.horizontal, 20)

                    featuresSection
                        .padding(.horizontal, 44)
                }
            }

            getCardButton
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .background(Colors.Background.primary.edgesIgnoringSafeArea(.all))
    }

    private var titleSection: some View {
        Text(Localization.tangempayOnboardingTitle)
            .style(Fonts.Bold.title1, color: Colors.Text.primary1)
            .multilineTextAlignment(.center)
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            featureRow(
                icon: Assets.Visa.securityCheck,
                title: Localization.tangempayOnboardingSecurityTitle,
                description: Localization.tangempayOnboardingSecurityDescription
            )

            featureRow(
                icon: Assets.Visa.shoppingBasket01,
                title: Localization.tangempayOnboardingPurchasesTitle,
                description: Localization.tangempayOnboardingPurchasesDescription
            )

            featureRow(
                icon: Assets.Visa.analyticsUp,
                title: Localization.tangempayOnboardingPayTitle,
                description: Localization.tangempayOnboardingPayDescription
            )
        }
    }

    private func featureRow(icon: ImageType, title: String, description: String) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Circle()
                .fill(Colors.Button.secondary)
                .frame(width: 40, height: 40)
                .overlay(
                    icon.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(Colors.Icon.primary1)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .style(Fonts.Bold.callout, color: Colors.Text.primary1)

                Text(description)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
            }

            Spacer()
        }
    }

    private var getCardButton: some View {
        MainButton(
            title: Localization.tangempayOnboardingGetCardButtonText,
            icon: .trailing(Assets.tangemIcon),
            style: .primary,
            action: viewModel.getCard
        )
        .setIsLoading(to: viewModel.isLoading)
    }
}
