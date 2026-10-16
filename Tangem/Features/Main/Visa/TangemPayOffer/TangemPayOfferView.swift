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

    @Environment(\.colorScheme) private var colorScheme

    private var isBundleIntroductionEnabled: Bool {
        FeatureProvider.isAvailable(.payBundleIntroduction)
    }

    var body: some View {
        TangemPayOnboardingContentView(
            showsLegalLine: isBundleIntroductionEnabled,
            usesBundleIntroductionLayout: isBundleIntroductionEnabled,
            getCardIcon: viewModel.showsGetCardIcon && !isBundleIntroductionEnabled ? DesignSystem.Icons.LogoTangem.regular24 : nil,
            titleAccessibilityIdentifier: nil,
            getCardButtonAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.onboardingGetCardButton,
            isLoading: viewModel.isLoading,
            onGetCard: viewModel.getCard,
            onLegalLinkTap: viewModel.openLegalDocument
        )
        .sheet(item: $viewModel.termsFeesAndLimitsViewModel) {
            WebViewContainer(viewModel: $0)
        }
        .sheet(item: $viewModel.legalDocumentViewModel) {
            WebViewContainer(viewModel: $0)
        }
        .alert(item: $viewModel.alert) { $0.alert }
        .environment(\.colorScheme, isBundleIntroductionEnabled ? .dark : colorScheme)
    }
}
