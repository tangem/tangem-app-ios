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
    let showsLegalLine: Bool
    let usesBundleIntroductionLayout: Bool
    let getCardIcon: ImageType?
    let titleAccessibilityIdentifier: String?
    let getCardButtonAccessibilityIdentifier: String
    let isLoading: Bool
    let onGetCard: () -> Void
    let onLegalLinkTap: (URL) -> Void

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

                featureGrid
                    .padding(.top, 36)
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

            VStack(spacing: 12) {
                if showsLegalLine {
                    legalLine
                }

                getCardButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, bundlePanelBottomPadding(safeAreaBottom: safeAreaBottom))
            .frame(maxWidth: .infinity)
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
                    featureGrid
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
        .styleType(.primary)
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
