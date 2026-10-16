//
//  TangemPayMobileOnboardingView.swift
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

struct TangemPayMobileOnboardingView: View {
    @ObservedObject var viewModel: TangemPayMobileOnboardingViewModel

    private var isBundleIntroductionEnabled: Bool {
        FeatureProvider.isAvailable(.payBundleIntroduction)
    }

    var body: some View {
        TangemPayOnboardingContentView(
            showsLegalLine: true,
            usesBundleIntroductionLayout: isBundleIntroductionEnabled,
            getCardIcon: nil,
            titleAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.mobileOnboardingTitle,
            getCardButtonAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.mobileOnboardingGetCardButton,
            isLoading: viewModel.isCreating,
            onGetCard: viewModel.getCard,
            onLegalLinkTap: viewModel.openLegalDocument
        )
        .toolbar {
            if isBundleIntroductionEnabled {
                ToolbarItem(placement: .topBarLeading) {
                    DesignSystem.Icons.LogoTangem.regular24.image
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(DesignSystem.Color.textPrimary)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                SwiftUI.Button(action: viewModel.onTermsTap) {
                    Assets.Visa.tangemPayOnboardingNewDoc.image
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(DesignSystem.Color.textPrimary)
                }
                .accessibilityLabel(Localization.tangemPayTermsFeesLimits)
            }
        }
        .environment(\.colorScheme, .dark)
        .alert(item: $viewModel.alert) { $0.alert }
        .onAppear(perform: viewModel.onAppear)
    }
}
