//
//  WelcomeV2View.swift
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

struct WelcomeV2View: View {
    @ObservedObject var viewModel: WelcomeV2ViewModel

    var body: some View {
        ZStack {
            WelcomeV2VideoBackgroundView(viewModel: viewModel.videoBackground)
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
                navigationBar
                    .padding(.horizontal, 16)
                    .frame(height: 44)

                Spacer(minLength: 0)

                titleBlock
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background {
                        LinearGradient(
                            colors: [.clear, .black],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }

                bottomContainer
            }
        }
        .onFirstAppear(perform: viewModel.onFirstAppear)
    }

    private var navigationBar: some View {
        HStack {
            Assets.newTangemLogo.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 24)

            Spacer()
        }
    }

    /// Every scene is laid out at once so the block keeps the height of the tallest one
    /// and the buttons below it don't jump while the texts fade.
    private var titleBlock: some View {
        ZStack(alignment: .topLeading) {
            ForEach(WelcomeV2Scene.allCases) { scene in
                sceneText(scene)
                    .opacity(viewModel.scene == scene ? 1 : 0)
                    .accessibilityHidden(viewModel.scene != scene)
            }
        }
        .animation(.easeInOut(duration: Constants.sceneFadeDuration), value: viewModel.scene)
    }

    private func sceneText(_ scene: WelcomeV2Scene) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(scene.title)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textStaticDarkPrimary)

            Text(scene.subtitle)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textStaticDarkSecondary)
        }
    }

    private var bottomContainer: some View {
        VStack(spacing: 12) {
            TangemUI.Button(
                label: Localization.introductionButtonCreateWallet,
                accessibilityLabel: nil,
                action: viewModel.onCreateWalletTap
            )
            .styleType(.default)
            .horizontalLayout(.infinity)
            .size(.x14)
            .accessibilityIdentifier(WelcomeV2AccessibilityIdentifiers.createWalletButton)

            TangemUI.Button(
                label: Localization.introductionButtonIHaveAWallet,
                accessibilityLabel: nil,
                action: viewModel.onExistingWalletTap
            )
            .styleType(.secondary(.default))
            .horizontalLayout(.infinity)
            .size(.x14)
            .accessibilityIdentifier(WelcomeV2AccessibilityIdentifiers.existingWalletButton)

            footer
                .padding(.horizontal, 24)
        }
        .padding(.horizontal, 16)
        .padding(.top, 15)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(Color.black)
                .ignoresSafeArea(edges: .bottom)
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
            string[range].font = Font.system(size: 12, weight: .semibold)
            string[range].link = WelcomeV2LegalDocument.termsOfService.url
        }

        if let range = string.range(of: privacy) {
            string[range].foregroundColor = DesignSystem.Color.textStaticDarkPrimary
            string[range].font = Font.system(size: 12, weight: .semibold)
            string[range].link = WelcomeV2LegalDocument.privacyPolicy.url
        }

        return string
    }
}

// MARK: - Constants

private extension WelcomeV2View {
    enum Constants {
        /// Fits the pause between two episodes, so a scene is fully gone before the next one appears.
        static let sceneFadeDuration: TimeInterval = 0.3
    }
}

// MARK: - Previews

#Preview {
    WelcomeV2View(
        viewModel: WelcomeV2ViewModel(
            coordinator: WelcomeV2Coordinator(),
            videoProvider: CommonWelcomeV2BackgroundVideoProvider()
        )
    )
}
