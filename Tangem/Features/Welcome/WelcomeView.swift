//
//  WelcomeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct WelcomeView: View {
    @ObservedObject var viewModel: WelcomeViewModel

    var body: some View {
        ZStack {
            videoBackground
                .ignoresSafeArea()

            LinearGradient(
                stops: [
                    Gradient.Stop(color: .clear, location: 0.5),
                    Gradient.Stop(color: .black.opacity(0.4), location: 0.7),
                    Gradient.Stop(color: .black.opacity(0.75), location: 0.85),
                    Gradient.Stop(color: .black, location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxHeight: .infinity)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                titleBlock
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background {
                        LinearGradient(
                            stops: [
                                Gradient.Stop(color: DesignSystem.Color.bgPrimary.opacity(0), location: 0.0),
                                Gradient.Stop(color: DesignSystem.Color.bgPrimary, location: 0.78),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea(edges: .horizontal)
                    }

                bottomContainer
            }
        }
        .topNavigation(
            leading: .image(Assets.newTangemLogo, height: 24),
            actions: .one(
                TopNavigation.Action(
                    title: Localization.introductionButtonBuyTangem,
                    accessibilityIdentifier: WelcomeAccessibilityIdentifiers.buyTangemButton,
                    action: viewModel.onBuyTangemTap
                )
            )
        )
        .environment(\.topNavigationDrawsBarBackground, false)
        .disabled(viewModel.isProcessing)
        .overlay {
            if viewModel.isProcessing {
                processingOverlay
            }
        }
        .onFirstAppear(perform: viewModel.onFirstAppear)
    }

    @ViewBuilder
    private var videoBackground: some View {
        switch viewModel.videoBackground {
        case .legacy(let videoViewModel):
            WelcomeVideoBackgroundView(viewModel: videoViewModel)
        case .shared(let videoViewModel):
            LoopingVideoBackgroundView(viewModel: videoViewModel, fitsWithBlurredBackdropWhenWide: true)
        }
    }

    /// All scenes are laid out at once (block keeps the tallest height, so buttons don't jump);
    /// bottom alignment pins the text to the buttons.
    private var titleBlock: some View {
        ZStack(alignment: .bottomLeading) {
            ForEach(WelcomeScene.allCases) { scene in
                WelcomeSceneText(scene: scene, isActive: viewModel.scene == scene)
                    .accessibilityHidden(viewModel.scene != scene)
            }
        }
    }

    private var bottomContainer: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                TangemUI.Button(
                    label: Localization.introductionButtonCreateWallet,
                    accessibilityLabel: nil,
                    action: viewModel.onCreateWalletTap
                )
                .styleType(.primary)
                .horizontalLayout(.infinity)
                .size(.x12)
                .accessibilityIdentifier(WelcomeAccessibilityIdentifiers.createWalletButton)

                TangemUI.Button(
                    label: Localization.introductionButtonIHaveAWallet,
                    accessibilityLabel: nil,
                    action: viewModel.onExistingWalletTap
                )
                .styleType(.secondary(.default))
                .horizontalLayout(.infinity)
                .size(.x12)
                .accessibilityIdentifier(WelcomeAccessibilityIdentifiers.existingWalletButton)
            }

            footer
                .padding(.horizontal, 24)
        }
        .padding(.horizontal, 16)
        .padding(.top, 15)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(DesignSystem.Color.bgPrimary)
                .ignoresSafeArea(edges: [.bottom, .horizontal])
        }
    }

    private var footer: some View {
        Text(footerAttributedString)
            .multilineTextAlignment(.center)
            .environment(\.openURL, OpenURLAction { url in
                viewModel.onLegalLinkTap(url)
                return .handled
            })
    }

    private var footerAttributedString: AttributedString {
        let terms = Localization.introductionTermsOfService
        let privacy = Localization.commonPrivacyPolicy
        var string = AttributedString(Localization.introductionLegal(terms, privacy))
        string.setFontStyle(DesignSystem.Font.captionMediumToken)
        string.foregroundColor = DesignSystem.Color.textStaticDarkSecondary

        if let range = string.range(of: terms) {
            string[range].foregroundColor = DesignSystem.Color.textStaticDarkPrimary
            string[range].link = WelcomeLegalDocument.termsOfService.url
        }

        if let range = string.range(of: privacy) {
            string[range].foregroundColor = DesignSystem.Color.textStaticDarkPrimary
            string[range].link = WelcomeLegalDocument.privacyPolicy.url
        }

        return string
    }

    private var processingOverlay: some View {
        ZStack {
            DesignSystem.Color.overlayModal
                .ignoresSafeArea(edges: .all)

            Loader()
                .loaderColor(DesignSystem.Color.iconSecondary)
                .loaderSize(.size32)
        }
    }
}

// MARK: - Previews

#Preview {
    WelcomeView(
        viewModel: WelcomeViewModel(
            coordinator: WelcomeCoordinator(),
            videoProvider: CommonWelcomeBackgroundVideoProvider()
        )
    )
}
