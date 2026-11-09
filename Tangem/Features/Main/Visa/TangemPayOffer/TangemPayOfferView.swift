//
//  TangemPayOfferView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemAccessibilityIdentifiers

struct TangemPayOfferView: View {
    @ObservedObject var viewModel: TangemPayOfferViewModel

    var body: some View {
        TangemPayOnboardingContentView(
            usesBundleIntroductionLayout: false,
            getCardIcon: viewModel.showsGetCardIcon ? DesignSystem.Icons.LogoTangem.regular24 : nil,
            titleAccessibilityIdentifier: nil,
            getCardButtonAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.onboardingGetCardButton,
            isLoading: viewModel.isLoading,
            onGetCard: viewModel.getCard,
            onLegalLinkTap: nil
        )
        .alert(item: $viewModel.alert) { $0.alert }
        .sheet(item: $viewModel.termsFeesAndLimitsViewModel) {
            WebViewContainer(viewModel: $0)
                .softTopScrollEdgeEffect()
        }
    }
}
