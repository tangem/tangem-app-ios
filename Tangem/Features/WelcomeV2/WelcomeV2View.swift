//
//  WelcomeV2View.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

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
        .preferredColorScheme(.dark)
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

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Store all your assets")
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textStaticDarkPrimary)

            Text("The only app you need\nto manage your finances")
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textStaticDarkSecondary)
        }
    }

    private var bottomContainer: some View {
        VStack(spacing: 12) {
            MainButton(
                title: "Create wallet",
                style: .primary,
                action: viewModel.onCreateWalletTap
            )

            MainButton(
                title: "I have a wallet",
                style: .secondary,
                action: viewModel.onExistingWalletTap
            )

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
        let terms = "Terms of service"
        let privacy = "Privacy Policy"
        var string = AttributedString("By continuing, you agree with \(terms) and \(privacy)")
        string.setFontStyle(DesignSystem.Font.captionMediumToken)
        string.foregroundColor = DesignSystem.Color.textStaticDarkSecondary

        if let range = string.range(of: terms) {
            string[range].foregroundColor = DesignSystem.Color.textStaticDarkPrimary
            string[range].font = Font.system(size: 12, weight: .semibold)
            string[range].link = AppConstants.tosURL
        }

        if let range = string.range(of: privacy) {
            string[range].foregroundColor = DesignSystem.Color.textStaticDarkPrimary
            string[range].font = Font.system(size: 12, weight: .semibold)
            // [REDACTED_TODO_COMMENT]
            string[range].link = URL(string: "about:blank")
        }

        return string
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
