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

struct TangemPayOfferViewV2: View {
    @ObservedObject var viewModel: TangemPayOfferViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Tokens.Spacing.none) {
                heroBackground

                VStack(spacing: DesignSystem.Tokens.Spacing.s300) {
                    textSection
                    featureGrid
                        .padding(.bottom, DesignSystem.Tokens.Spacing.s300)
                    faqSection
                }
                .padding(.horizontal, DesignSystem.Tokens.Spacing.s300)
                .padding(.top, -112)
                .background(DesignSystem.Tokens.Theme.Bg.primary)
            }
        }
        .ignoresSafeArea(edges: .top)
        .safeAreaInset(edge: .bottom) { footer }
        .background {
            DesignSystem.Tokens.Theme.Bg.primary
                .ignoresSafeArea()
        }
        .environment(\.colorScheme, .dark)
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
                        .init(color: DesignSystem.Tokens.Theme.Bg.primary, location: 0.75),
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
        VStack(alignment: .leading, spacing: DesignSystem.Tokens.Spacing.s100) {
            Text(Localization.tangempayNewonboardTitle)
                .font(DesignSystem.Tokens.Font.Heading.medium)
                .foregroundStyle(DesignSystem.Tokens.Theme.Text.primary)

            Text(Localization.tangempayNewonboardBody)
                .font(DesignSystem.Tokens.Font.Subheading.medium)
                .foregroundStyle(DesignSystem.Tokens.Theme.Text.secondary)
        }
    }

    private var featureGrid: some View {
        let columns = [GridItem(.flexible(), spacing: DesignSystem.Tokens.Spacing.s100), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: DesignSystem.Tokens.Spacing.s100) {
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
        VStack(alignment: .leading, spacing: DesignSystem.Tokens.Spacing.s350) {
            icon.image
                .renderingMode(.template)
                .resizable()
                .frame(size: .init(bothDimensions: DesignSystem.Tokens.Size.s300))
                .foregroundStyle(DesignSystem.Tokens.Theme.Text.primary)

            VStack(alignment: .leading, spacing: DesignSystem.Tokens.Spacing.none) {
                Text(primary)
                    .font(DesignSystem.Tokens.Font.Caption.medium)
                    .foregroundStyle(DesignSystem.Tokens.Theme.Text.primary)

                Text(secondary)
                    .font(DesignSystem.Tokens.Font.Caption.medium)
                    .foregroundStyle(DesignSystem.Tokens.Theme.Text.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Tokens.Spacing.s200)
        .background(DesignSystem.Tokens.Theme.Bg.secondary)
        .cornerRadiusContinuous(DesignSystem.Tokens.CornerRadius._300)
    }

    private var faqSection: some View {
        VStack(spacing: DesignSystem.Tokens.Spacing.none) {
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
        VStack(alignment: .leading, spacing: DesignSystem.Tokens.Spacing.s150) {
            if showDivider {
                Color.white.opacity(0.1)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, DesignSystem.Tokens.Spacing.s150)
            }

            Text(question)
                .font(DesignSystem.Tokens.Font.Heading.small)
                .foregroundStyle(DesignSystem.Tokens.Theme.Text.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(answer)
                .font(DesignSystem.Tokens.Font.Subheading.medium)
                .foregroundStyle(DesignSystem.Tokens.Theme.Text.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, showDivider ? DesignSystem.Tokens.Spacing.s300 : DesignSystem.Tokens.Spacing.s150)
        .padding(.bottom, DesignSystem.Tokens.Spacing.s150)
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
        .padding(.horizontal, DesignSystem.Tokens.Spacing.s200)
        .padding(.bottom, DesignSystem.Tokens.Spacing.s150)
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
