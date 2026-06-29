//
//  WalletPromoBannerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct WalletPromoBannerView: View {
    @ObservedObject var viewModel: WalletPromoBannerViewModel

    @ScaledMetric private var padding: CGFloat = .unit(.x3)
    @ScaledMetric private var iconWidth: CGFloat = 176
    @ScaledMetric private var iconHeight: CGFloat = 128
    @ScaledMetric private var titlePadding: CGFloat = .unit(.x2)
    @ScaledMetric private var descriptionPadding: CGFloat = .unit(.x1)
    @ScaledMetric private var actionPadding: CGFloat = .unit(.x5)

    private let cornerRadius: CGFloat = .unit(.x6)

    var body: some View {
        if FeatureProvider.isAvailable(.redesign) {
            redesignBody
        } else {
            legacyBody
        }
    }

    private var redesignBody: some View {
        VStack(spacing: 0) {
            Assets.walletPromoImage.image
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: iconWidth, height: iconHeight)

            Text(Localization.walletPromoBannerTitle)
                .style(Font.Tangem.Body16.semibold, color: .Tangem.Text.Neutral.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, titlePadding)

            Text(Localization.walletPromoBannerDescription)
                .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, descriptionPadding)

            TangemButton(
                content: .text(AttributedString(Localization.walletPromoBannerButtonTitle)),
                action: viewModel.didTapWalletPromo
            )
            .setStyleType(.primary)
            .setHorizontalLayout(.infinity)
            .setSize(.x9)
            .padding(.top, actionPadding)
        }
        .padding(padding)
        .background(Color.Tangem.Surface.level3)
        .glowBorder(effect: .bannerMagic, cornerRadius: cornerRadius)
        .environment(\.colorScheme, .dark)
        .onAppear(perform: viewModel.onAppear)
    }

    private var legacyBody: some View {
        VStack(alignment: .center, spacing: 0) {
            Assets.walletPromoImage.image

            Text(Localization.walletPromoBannerTitle)
                .style(Fonts.Bold.title3, color: Colors.Text.constantWhite)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 12)

            Text(Localization.walletPromoBannerDescription)
                .multilineTextAlignment(.center)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 12)

            MainButton(
                title: Localization.walletPromoBannerButtonTitle,
                style: .primary,
                size: .notification,
                action: viewModel.didTapWalletPromo
            )
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 14)
        .background(Colors.Background.primary)
        .environment(\.colorScheme, .dark)
        .cornerRadiusContinuous(14)
        .onAppear(perform: viewModel.onAppear)
    }
}
