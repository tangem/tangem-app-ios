//
//  TangemPayOfferViewV2.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct TangemPayOfferViewV2: View {
    @ObservedObject var viewModel: TangemPayOfferViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroBackground

                VStack(spacing: 24) {
                    textSection
                    featureGrid
                        .padding(.bottom, 24)
                    faqSection
                }
                .padding(.horizontal, 24)
                .padding(.top, -112)
                .background(DesignSystem.Color.bgPrimary)
            }
        }
        .ignoresSafeArea(edges: .top)
        .safeAreaInset(edge: .bottom) { footer }
        .background {
            DesignSystem.Color.bgPrimary
                .ignoresSafeArea()
        }
        .sheet(item: $viewModel.termsFeesAndLimitsViewModel) {
            WebViewContainer(viewModel: $0)
        }
    }

    private var heroBackground: some View {
        Assets.Visa.tangemPayOnboardingBg.image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: DesignSystem.Color.bgPrimary, location: 0.75),
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .overlay {
                Assets.Visa.tangemPayOnboardingHero.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Localization.tangempayNewonboardTitle)
                .font(token: DesignSystem.Font.headingMediumToken)
                .foregroundStyle(DesignSystem.Color.textPrimary)

            Text(Localization.tangempayNewonboardBody)
                .font(token: DesignSystem.Font.subheadingMediumToken)
                .foregroundStyle(DesignSystem.Color.textSecondary)
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
    }

    private var featureGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 8) {
            featureTile(
                icon: Assets.Visa.tangemPayOnboardingNewLightning,
                primary: Localization.tangempayNewonboardTopleftTitle,
                secondary: Localization.tangempayNewonboardTopleftBody
            )
            featureTile(
                icon: Assets.Visa.tangemPayOnboardingNewHeart,
                primary: Localization.tangempayNewonboardToprightTitle,
                secondary: Localization.tangempayNewonboardToprightBody
            )
            featureTile(
                icon: Assets.Visa.tangemPayOnboardingNewShield,
                primary: Localization.tangempayNewonboardBottomleftTitle,
                secondary: Localization.tangempayNewonboardBottomleftBody
            )
            featureTile(
                icon: Assets.Visa.tangemPayOnboardingNewPercent,
                primary: Localization.tangempayNewonboardBottomrightTitle,
                secondary: Localization.tangempayNewonboardBottomrightBody
            )
        }
    }

    private func featureTile(icon: ImageType, primary: String, secondary: String) -> some View {
        let label = (
            Text(primary)
                .foregroundColor(DesignSystem.Color.textPrimary)
                + Text("\n" + secondary)
                .foregroundColor(DesignSystem.Color.textSecondary)
        )
        .font(token: DesignSystem.Font.captionMediumToken)

        return VStack(alignment: .leading, spacing: 28) {
            icon.image
                .renderingMode(.template)
                .resizable()
                .frame(size: .init(bothDimensions: 24))
                .foregroundStyle(DesignSystem.Color.textPrimary)

            label
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .background(DesignSystem.Color.bgSecondary)
        .cornerRadiusContinuous(24)
    }

    private var faqSection: some View {
        VStack(spacing: 0) {
            faqItem(
                question: Localization.tangempayNewonboardQ1Title,
                answer: Localization.tangempayNewonboardQ1Body,
                showDivider: false
            )
            faqItem(
                question: Localization.tangempayNewonboardQ2Title,
                answer: Localization.tangempayNewonboardQ2Body,
                showDivider: true
            )
            faqItem(
                question: Localization.tangempayNewonboardQ3Title,
                answer: Localization.tangempayNewonboardQ3Body,
                showDivider: true
            )
            faqItem(
                question: Localization.tangempayNewonboardQ4Title,
                answer: Localization.tangempayNewonboardQ4Body,
                showDivider: true
            )
        }
    }

    private func faqItem(question: String, answer: String, showDivider: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if showDivider {
                DesignSystem.Color.borderSecondary
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 12)
            }

            Text(question)
                .font(token: DesignSystem.Font.headingSmallToken)
                .foregroundStyle(DesignSystem.Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(answer)
                .font(token: DesignSystem.Font.subheadingMediumToken)
                .foregroundStyle(DesignSystem.Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, showDivider ? 24 : 12)
        .padding(.bottom, 12)
    }

    private var footer: some View {
        TangemButtonV2(
            label: .init(Localization.tangempayOnboardingGetCardButtonText),
            iconEnd: DesignSystem.Icons.LogoTangem.regular24,
            accessibilityLabel: nil
        ) {
            viewModel.getCard()
        }
        .styleType(.default)
        .horizontalLayout(.infinity)
        .isLoading(viewModel.isLoading)
        .size(.x12)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.onboardingGetCardButton)
    }
}

#Preview {
    NavigationStack {
        TangemPayOfferViewV2(
            viewModel: TangemPayOfferViewModel(
                walletSelectionType: .single(""),
                closeOfferScreen: {},
                coordinator: nil
            )
        )
    }
}
