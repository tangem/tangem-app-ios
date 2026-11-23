//
//  OnrampOffersSelectorSheetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct OnrampOffersSelectorSheetView: View {
    @ObservedObject var viewModel: OnrampOffersSelectorViewModel

    private var subtitle: String {
        switch viewModel.viewState {
        case .paymentMethods: Localization.onrampPaymentMethodSubtitle
        case .offers: Localization.onrampProvidersSubtitle
        }
    }

    private var backAction: (() -> Void)? {
        switch viewModel.viewState {
        case .paymentMethods: nil
        case .offers: viewModel.back
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

            ScrollView {
                OnrampOffersSelectorView(viewModel: viewModel)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackground = .color(DesignSystem.Color.bgPrimary)
            configuration.sheetFrameUpdateAnimation = .curve(.easeInOutRefined, duration: 0.5)
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}
