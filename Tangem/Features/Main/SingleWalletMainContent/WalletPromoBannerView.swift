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
import TangemUIUtils

struct WalletPromoBannerView: View {
    @ObservedObject var viewModel: WalletPromoBannerViewModel

    @ScaledMetric private var imageSide: CGFloat = 64

    var body: some View {
        MessageBanner(
            title: Localization.walletPromoBannerTitle,
            description: Localization.walletPromoBannerDescription
        )
        .slotEnd {
            Assets.walletPromoImage.image
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: imageSide, height: imageSide)
        }
        .primaryButton(
            .init(title: Localization.walletPromoBannerButtonTitle, action: viewModel.didTapWalletPromo)
        )
        .glowRing(.magic)
        .onAppear(perform: viewModel.onAppear)
    }
}
