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
        // [REDACTED_TODO_COMMENT]
        Text("Get your free Crypto Card in minutes")
            .style(Fonts.Bold.title1, color: Colors.Text.primary1)
            .multilineTextAlignment(.center)
    }

    // [REDACTED_TODO_COMMENT]
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            featureRow(
                icon: Assets.Visa.securityCheck,
                title: "Built-in security",
                description: "Your card details are protected — full control in the app."
            )

            featureRow(
                icon: Assets.Visa.shoppingBasket01,
                title: "Everyday purchases",
                description: "Use your USDC balance to pay for everyday purchases seamlessly."
            )

            featureRow(
                icon: Assets.Visa.analyticsUp,
                title: "Apple Pay & Google Pay",
                description: "Add to your wallet and pay with your phone anywhere."
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
        // [REDACTED_TODO_COMMENT]
        MainButton(
            title: "Get card",
            icon: .trailing(Assets.tangemIcon),
            style: .primary,
            action: viewModel.getCard
        )
        .setIsLoading(to: viewModel.isLoading)
    }
}
