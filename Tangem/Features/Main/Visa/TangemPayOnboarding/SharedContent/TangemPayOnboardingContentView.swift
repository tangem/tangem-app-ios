//
//  TangemPayOnboardingContentView.swift
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

struct TangemPayOnboardingContentView: View {
    let usesBundleIntroductionLayout: Bool
    let getCardIcon: ImageType?
    let titleAccessibilityIdentifier: String?
    let getCardButtonAccessibilityIdentifier: String
    let isLoading: Bool
    let onGetCard: () -> Void
    let onLegalLinkTap: ((URL) -> Void)?

    @StateObject private var videoViewModel = LoopingVideoBackgroundViewModel(
        provider: TangemPayOnboardingVideoProvider()
    )

    @State private var scroll = TangemPayOnboardingScrollState()

    var body: some View {
        if usesBundleIntroductionLayout {
            bundleLayout
        } else {
            scrollLayout
        }
    }

    // MARK: - Bundle layout (pinned video backdrop, parallax scroll)

    private var bundleLayout: some View {
        GeometryReader { proxy in
            let safeArea = proxy.safeAreaInsets
            let screenHeight = proxy.size.height + safeArea.top + safeArea.bottom
            let heroHeight = (screenHeight * Constants.heroHeightRatio).rounded()

            ZStack(alignment: .top) {
                TangemPayOnboardingBackdrop(scroll: scroll, videoViewModel: videoViewModel)

                bundleScrollContent(heroHeight: heroHeight, safeAreaBottom: safeArea.bottom)
            }
        }
        .background(DesignSystem.Color.bgPrimary)
    }

    private func bundleScrollContent(heroHeight: CGFloat, safeAreaBottom: CGFloat) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                textSection

                features
                    .padding(.top, 36)

                if let onLegalLinkTap {
                    legalLine(onLinkTap: onLegalLinkTap)
                        .padding(.top, 24)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, heroHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(alignment: .top) {
                TangemPayOnboardingSheetBackground(heroHeight: heroHeight)
            }
            .onGeometryChange(for: CGFloat.self) { geometry in
                geometry.frame(in: .named(Constants.scrollCoordinateSpace)).minY
            } action: { minY in
                scroll.offset = -minY
            }
        }
        .scrollIndicators(.hidden)
        .coordinateSpace(name: Constants.scrollCoordinateSpace)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bundleBottomPanel(safeAreaBottom: safeAreaBottom)
        }
        .ignoresSafeArea(.container, edges: .top)
    }

    private func bundleBottomPanel(safeAreaBottom: CGFloat) -> some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [DesignSystem.Color.bgPrimary.opacity(0), DesignSystem.Color.bgPrimary],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)
            .allowsHitTesting(false)

            getCardButton
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, bundlePanelBottomPadding(safeAreaBottom: safeAreaBottom))
                .background(DesignSystem.Color.bgPrimary)
        }
    }

    private func bundlePanelBottomPadding(safeAreaBottom: CGFloat) -> CGFloat {
        safeAreaBottom > 0 ? Constants.buttonBottomInset - safeAreaBottom : Constants.buttonBottomInsetWithoutHomeIndicator
    }

    // MARK: - Scroll layout (static hero)

    private var scrollLayout: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroBackground

                VStack(spacing: 36) {
                    textSection

                    VStack(spacing: 24) {
                        features

                        if let onLegalLinkTap {
                            legalLine(onLinkTap: onLegalLinkTap)
                        }
                    }
                    .padding(.bottom, 24)
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

    // MARK: - Shared content

    private var content: Content {
        TangemPayUnifiedOnboarding.isEnabled ? .unified : .card
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(content.title)
                .font(token: DesignSystem.Font.headingMediumToken)
                .foregroundStyle(DesignSystem.Color.textPrimary)
                .accessibilityIdentifier(titleAccessibilityIdentifier)

            Text(content.body)
                .font(token: DesignSystem.Font.subheadingMediumToken)
                .foregroundStyle(DesignSystem.Color.textSecondary)
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
    }

    @ViewBuilder
    private var features: some View {
        switch content.features {
        case .iconGrid(let topLeft, let topRight, let bottomLeft, let bottomRight):
            featureGrid(topLeft: topLeft, topRight: topRight, bottomLeft: bottomLeft, bottomRight: bottomRight)
        case .sections(let sections):
            featureSections(sections)
        }
    }

    private func featureGrid(
        topLeft: Content.Tile,
        topRight: Content.Tile,
        bottomLeft: Content.Tile,
        bottomRight: Content.Tile
    ) -> some View {
        let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 8) {
            featureTile(icon: Assets.Visa.tangemPayOnboardingNewLightning, primary: topLeft.primary, secondary: topLeft.secondary)
            featureTile(icon: Assets.Visa.tangemPayOnboardingNewHeart, primary: topRight.primary, secondary: topRight.secondary)
            featureTile(icon: Assets.Visa.tangemPayOnboardingNewShield, primary: bottomLeft.primary, secondary: bottomLeft.secondary)
            featureTile(icon: Assets.Visa.tangemPayOnboardingNewPercent, primary: bottomRight.primary, secondary: bottomRight.secondary)
        }
    }

    private func featureSections(_ sections: [Content.FeatureSection]) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(sections, id: \.title) { section in
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.title)
                        .font(token: DesignSystem.Font.subheadingMediumToken)
                        .foregroundStyle(DesignSystem.Color.textSecondary)
                        .padding(.vertical, 8)

                    VStack(spacing: 8) {
                        ForEach(section.rows, id: \.self) { row in
                            HStack(alignment: .top, spacing: 8) {
                                ForEach(row, id: \.caption) { card in
                                    featureCard(card)
                                }
                            }
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private func featureCard(_ card: Content.FeatureCard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.caption)
                .font(token: DesignSystem.Font.captionMediumToken)
                .foregroundStyle(DesignSystem.Color.textSecondary)

            Text(featureValue(card))
                .font(token: DesignSystem.Font.headingSmallToken)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .background(DesignSystem.Color.bgSecondary)
        .cornerRadiusContinuous(24)
    }

    private func featureValue(_ card: Content.FeatureCard) -> AttributedString {
        var value = AttributedString(card.value)
        value.foregroundColor = DesignSystem.Color.textPrimary

        if let secondaryPart = card.secondaryPart, let range = value.range(of: secondaryPart) {
            value[range].foregroundColor = DesignSystem.Color.textSecondary
        }

        return value
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

    private var footer: some View {
        getCardButton
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
    }

    private var getCardButton: some View {
        TangemUI.Button(
            label: content.buttonTitle,
            accessibilityLabel: nil
        ) {
            onGetCard()
        }
        .iconEnd(getCardIcon)
        .styleType(.primary)
        .horizontalLayout(.infinity)
        .loading(.spinner(if: isLoading))
        .size(.x12)
        .accessibilityIdentifier(getCardButtonAccessibilityIdentifier)
    }

    private func legalLine(onLinkTap: @escaping (URL) -> Void) -> some View {
        Text(legalAttributedString)
            .multilineTextAlignment(.center)
            .infinityFrame(axis: .horizontal)
            .environment(\.openURL, OpenURLAction { url in
                onLinkTap(url)
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
            string[range].link = AppConstants.tangemPayTermsOfServiceURL
        }

        if let range = string.range(of: privacy) {
            string[range].foregroundColor = DesignSystem.Color.textPrimary
            string[range].link = AppConstants.tangemPayOnboardingPrivacyPolicyURL
        }

        return string
    }
}

private extension TangemPayOnboardingContentView {
    enum Constants {
        static let heroHeightRatio: CGFloat = 0.58
        static let buttonBottomInset: CGFloat = 32
        static let buttonBottomInsetWithoutHomeIndicator: CGFloat = 16
        static let scrollCoordinateSpace = "TangemPayOnboardingScroll"
    }
}

private extension TangemPayOnboardingContentView {
    struct Content {
        struct Tile {
            let primary: String
            let secondary: String
        }

        struct FeatureCard: Hashable {
            let caption: String
            let value: String
            let secondaryPart: String?
        }

        struct FeatureSection {
            let title: String
            let rows: [[FeatureCard]]
        }

        enum Features {
            case iconGrid(topLeft: Tile, topRight: Tile, bottomLeft: Tile, bottomRight: Tile)
            case sections([FeatureSection])
        }

        let title: String
        let body: String
        let features: Features
        let buttonTitle: String

        static let card = Content(
            title: Localization.tangempayNewonboardTitle,
            body: Localization.tangempayNewonboardBody,
            features: .iconGrid(
                topLeft: Tile(
                    primary: Localization.tangempayNewonboardTopleftTitle,
                    secondary: Localization.tangempayNewonboardTopleftBody
                ),
                topRight: Tile(
                    primary: Localization.tangempayNewonboardToprightTitle,
                    secondary: Localization.tangempayNewonboardToprightBody
                ),
                bottomLeft: Tile(
                    primary: Localization.tangempayNewonboardBottomleftTitle,
                    secondary: Localization.tangempayNewonboardBottomleftBody
                ),
                bottomRight: Tile(
                    primary: Localization.tangempayNewonboardBottomrightTitle,
                    secondary: Localization.tangempayNewonboardBottomrightBody
                )
            ),
            buttonTitle: Localization.tangempayOnboardingGetCardButtonText
        )

        static let unified = Content(
            title: Localization.tangempayTitle,
            body: Localization.tangempayUnifiedOnboardingDescription,
            features: .sections([
                FeatureSection(
                    title: Localization.tangempayUnifiedOnboardingPaymentAccountHeader,
                    rows: [[
                        FeatureCard(
                            caption: Localization.tangempayUnifiedOnboardingCashbackCaption,
                            value: Localization.tangempayUnifiedOnboardingCashbackTitle(
                                Localization.tangempayUnifiedOnboardingCashbackSubtitle
                            ),
                            secondaryPart: Localization.tangempayUnifiedOnboardingCashbackSubtitle
                        ),
                        FeatureCard(
                            caption: Localization.tangempayUnifiedOnboardingPaymentAccountCaption,
                            value: Localization.tangempayUnifiedOnboardingPaymentAccountTitle,
                            secondaryPart: nil
                        ),
                    ]]
                ),
                FeatureSection(
                    title: Localization.tangempayUnifiedOnboardingMoneyAccountHeader,
                    rows: [
                        [FeatureCard(
                            caption: Localization.tangempayUnifiedOnboardingFeesCaption,
                            value: Localization.tangempayUnifiedOnboardingFeesTitle(Localization.tangempayUnifiedOnboardingFeesSubtitle),
                            secondaryPart: Localization.tangempayUnifiedOnboardingFeesSubtitle
                        )],
                        [
                            FeatureCard(
                                caption: Localization.tangempayUnifiedOnboardingMoneyAccountCaption,
                                value: Localization.tangempayUnifiedOnboardingMoneyAccountTitleV2,
                                secondaryPart: nil
                            ),
                            FeatureCard(
                                caption: Localization.tangempayUnifiedOnboardingPaymentsCaption,
                                value: Localization.tangempayUnifiedOnboardingPaymentsTitle,
                                secondaryPart: nil
                            ),
                        ],
                        [FeatureCard(
                            caption: Localization.tangempayUnifiedOnboardingInterestCaption,
                            value: Localization.tangempayUnifiedOnboardingInterestTitle,
                            secondaryPart: nil
                        )],
                    ]
                ),
            ]),
            buttonTitle: Localization.commonGetStarted
        )
    }
}
