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
import TangemLocalization
import TangemAccessibilityIdentifiers

struct OnrampOffersSelectorView: View {
    @ObservedObject var viewModel: OnrampOffersSelectorViewModel

    var subtitle: String {
        switch viewModel.viewState {
        case .paymentMethods: Localization.onrampPaymentMethodSubtitle
        case .offers: Localization.onrampProvidersSubtitle
        }
    }

    var backAction: (() -> Void)? {
        switch viewModel.viewState {
        case .paymentMethods: nil
        case .offers: viewModel.back
        }
    }

    var contentSpacing: CGFloat {
        switch viewModel.viewState {
        case .paymentMethods: 4
        case .offers: 8
        }
    }

    var body: some View {
        VStack(spacing: .zero) {
            OnrampSheetHeaderView(
                title: Localization.onrampAllOffersButtonTitle,
                subtitle: subtitle,
                titleAccessibilityIdentifier: OnrampAccessibilityIdentifiers.providersScreenTitle,
                backAction: backAction,
                closeAction: viewModel.close
            )

            GroupedScrollView(contentType: .plain(alignment: .leading, spacing: contentSpacing)) {
                if let standaloneMarketingBanners = viewModel.standaloneMarketingBanners {
                    StandaloneMarketingBannersView(banners: standaloneMarketingBanners)
                }

                if let restrictedNotificationInput = viewModel.restrictedNotificationInput {
                    NotificationView(input: restrictedNotificationInput)
                }

                content
            }
            .scrollBounceBehavior(.basedOnSize)
            .animation(.contentFrameUpdate, value: viewModel.viewState.isPaymentMethods)
            .padding(.bottom, 16)
        }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackground = .color(DesignSystem.Color.bgPrimary)
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    @ViewBuilder
    var content: some View {
        switch viewModel.viewState {
        case .paymentMethods(let paymentMethods):
            ForEach(paymentMethods) {
                OnrampProviderItemView(viewModel: $0)
            }
        case .offers(let providers):
            ForEach(providers) {
                OnrampOfferView(viewModel: $0, cardBackground: DesignSystem.Color.bgTransparentPrimary)
            }
        }
    }
}

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}
