//
//  TangemPayVerifiedView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemPay
import TangemUI
import TangemUIUtils

struct TangemPayVerifiedView: View {
    @ObservedObject var viewModel: TangemPayVerifiedViewModel

    var body: some View {
        content
            .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.close)
            }
            .alert(item: $viewModel.alert) { $0.alert }
            .task { await viewModel.loadProductsAvailabilityIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            Loader()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let products):
            StatusScreen(
                title: Localization.tangempayVerifiedTitle,
                description: viewModel.description,
                actionTitle: viewModel.primaryActionTitle,
                action: viewModel.primaryAction
            )
            .appearance(.success)
            .actionLoading(viewModel.isStartingOnboarding)
            .actionSigning(viewModel.primaryActionSigningType)
            .details { productRows(products) }
        }
    }

    private func productRows(_ products: TangemPayProductsAvailability) -> some View {
        VStack(spacing: 0) {
            productRow(
                title: Localization.moneyAccountMainName,
                subtitle: Localization.tangempayVerifiedMoneyAccountSubtitle,
                isAvailable: products.isAccountAvailable,
                showsDivider: true
            )
            productRow(
                title: Localization.tangempayVerifiedPaymentAccountTitle,
                subtitle: Localization.tangempayVerifiedPaymentAccountSubtitle,
                isAvailable: products.isCardAvailable,
                showsDivider: false
            )
        }
    }

    private func productRow(title: String, subtitle: String, isAvailable: Bool, showsDivider: Bool) -> some View {
        Row(
            title: title,
            subtitle: isAvailable ? subtitle : Localization.tangempayVerifiedProductNotAvailable
        )
        .overrideTextColors(.init(title: isAvailable ? nil : DesignSystem.Color.textSecondary))
        .showDivider(showsDivider)
        .end {
            Badge(
                label: isAvailable ? Localization.tangempayVerifiedBadgeAvailable : Localization.commonLater,
                accessibilityLabel: nil
            )
            .appearance(isAvailable ? .success : .warning)
        }
    }
}
