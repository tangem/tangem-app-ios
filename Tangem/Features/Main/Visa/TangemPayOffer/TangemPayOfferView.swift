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
    let viewModel: TangemPayOfferViewModel

    var body: some View {
        GeometryReader { proxy in
            content(screenWidth: proxy.size.width)
        }
    }

    private func content(screenWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    circleCardImageView(circleSize: screenWidth * 0.625)

                    titleSection
                        .padding(.horizontal, 20)

                    featuresSection
                        .padding(.horizontal, 44)
                }
            }

            orderButton
                .padding(.horizontal, 16)
        }
        .background(Colors.Background.primary.edgesIgnoringSafeArea(.all))
    }

    private func circleCardImageView(circleSize: CGFloat) -> some View {
        Circle()
            .fill(Colors.Background.tertiary)
            .frame(width: circleSize, height: circleSize)
            .padding(.horizontal, 10)
            .overlay(cardImageView)
    }

    private var cardImageView: some View {
        Assets.Visa.card.image
            .resizable()
            .aspectRatio(contentMode: .fit)
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

    private var orderButton: some View {
        // [REDACTED_TODO_COMMENT]
        MainButton(
            title: "Order card",
            icon: .trailing(Assets.tangemIcon),
            style: .primary,
            action: viewModel.orderCard
        )
    }
}
