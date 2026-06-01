//
//  TangemPayMobileOnboardingView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct TangemPayMobileOnboardingView: View {
    @ObservedObject var viewModel: TangemPayMobileOnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Text(Localization.tangempayOnboardingTitle)
                .style(Fonts.Bold.title1, color: Colors.Text.constantWhite)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 24)

            Assets.Visa.tangemPayOnboardingHero.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)

            Spacer()

            featuresSection
                .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 8) {
                getCardButton

                termsFeesAndLimitsButton

                OnboardingTermsOfServiceFooter(onTap: viewModel.onTosTap)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .environment(\.colorScheme, .dark)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient.ignoresSafeArea())
        .alert(item: $viewModel.alert, content: { $0.alert })
        .onAppear(perform: viewModel.onAppear)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0x25 / 255, green: 0x26 / 255, blue: 0x2A / 255), location: 0),
                .init(color: .black, location: 0.75),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            featureRow(
                icon: Assets.Visa.mobileWalletIcon,
                title: Localization.tangempayOnboardingSetupWalletTitle,
                description: Localization.tangempayOnboardingSetupWalletDescription
            )

            featureRow(
                icon: Assets.Visa.shoppingBasket01,
                title: Localization.tangempayOnboardingPurchasesTitle,
                description: Localization.tangempayOnboardingPurchasesDescription
            )

            featureRow(
                icon: Assets.Visa.creditCardAdd,
                title: Localization.tangempayOnboardingPayTitle,
                description: Localization.tangempayOnboardingPayDescription
            )
        }
    }

    private func featureRow(icon: ImageType, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            icon.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .style(Fonts.Bold.callout, color: Colors.Text.constantWhite)
                Text(description)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
            }

            Spacer()
        }
    }

    private var getCardButton: some View {
        MainButton(
            title: Localization.tangempayOnboardingGetCardButtonText,
            style: .primary,
            action: viewModel.getCard
        )
        .setIsLoading(to: viewModel.isCreating)
    }

    private var termsFeesAndLimitsButton: some View {
        Button(action: viewModel.onTermsTap) {
            Text(Localization.tangemPayTermsFeesLimits)
                .style(Fonts.Bold.callout, color: Colors.Text.constantWhite)
        }
    }
}
