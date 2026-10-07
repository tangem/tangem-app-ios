//
//  TangemPayOnboardingContentView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct TangemPayOnboardingContentView: View {
    let showsFAQ: Bool
    let showsLegalLine: Bool
    let getCardIcon: ImageType?
    let titleAccessibilityIdentifier: String?
    let getCardButtonAccessibilityIdentifier: String
    let isLoading: Bool
    let onGetCard: () -> Void
    let onLegalLinkTap: (URL) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroBackground

                VStack(spacing: 24) {
                    textSection
                    featureGrid
                        .padding(.bottom, 24)
                    if showsFAQ {
                        faqSection
                    }
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
                .accessibilityIdentifier(titleAccessibilityIdentifier)

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
        VStack(spacing: 12) {
            if showsLegalLine {
                legalLine
            }

            getCardButton
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var getCardButton: some View {
        TangemUI.Button(
            label: Localization.tangempayOnboardingGetCardButtonText,
            accessibilityLabel: nil
        ) {
            onGetCard()
        }
        .iconEnd(getCardIcon)
        .styleType(.default)
        .horizontalLayout(.infinity)
        .loading(.spinner(if: isLoading))
        .size(.x12)
        .accessibilityIdentifier(getCardButtonAccessibilityIdentifier)
    }

    private var legalLine: some View {
        Text(legalAttributedString)
            .multilineTextAlignment(.center)
            .environment(\.openURL, OpenURLAction { url in
                onLegalLinkTap(url)
                return .handled
            })
    }

    private var legalAttributedString: AttributedString {
        let terms = Localization.introductionTermsOfService
        let privacy = Localization.commonPrivacyPolicy
        var string = AttributedString(Localization.introductionLegal(terms, privacy))
        string.setFontStyle(DesignSystem.Font.captionMediumToken)
        string.foregroundColor = DesignSystem.Color.textSecondary

        if let range = string.range(of: terms) {
            string[range].foregroundColor = DesignSystem.Color.textPrimary
            string[range].link = AppConstants.tosURL
        }

        if let range = string.range(of: privacy) {
            string[range].foregroundColor = DesignSystem.Color.textPrimary
            string[range].link = AppConstants.privacyPolicyURL
        }

        return string
    }
}
