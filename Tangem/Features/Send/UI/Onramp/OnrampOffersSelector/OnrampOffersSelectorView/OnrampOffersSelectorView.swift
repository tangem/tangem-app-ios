//
//  OnrampOffersSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct OnrampOffersSelectorView: View {
    @ObservedObject var viewModel: OnrampOffersSelectorViewModel

    var contentSpacing: CGFloat {
        switch viewModel.viewState {
        case .paymentMethods: 4
        case .offers: 8
        }
    }

    private var cardBackground: Color {
        viewModel.presentsInModal ? DesignSystem.Color.bgTransparentOnMaterialPrimary : DesignSystem.Color.bgTransparentPrimary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: contentSpacing) {
            if let standaloneMarketingBanners = viewModel.standaloneMarketingBanners {
                StandaloneMarketingBannersView(banners: standaloneMarketingBanners)
            }

            if let restrictedNotificationInput = viewModel.restrictedNotificationInput {
                NotificationView(input: restrictedNotificationInput)
            }

            content
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .animation(.contentFrameUpdate, value: viewModel.viewState.isPaymentMethods)
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }

    @ViewBuilder
    var content: some View {
        switch viewModel.viewState {
        case .paymentMethods(let paymentMethods):
            ForEach(paymentMethods) {
                OnrampProviderItemView(viewModel: $0, background: cardBackground)
            }
        case .offers(let providers):
            ForEach(providers) {
                OnrampOfferView(viewModel: $0, cardBackground: cardBackground)
            }
        }
    }
}

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}
