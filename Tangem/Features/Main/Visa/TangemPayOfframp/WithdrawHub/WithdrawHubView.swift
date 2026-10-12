//
//  WithdrawHubView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct WithdrawHubView: View {
    @ObservedObject var viewModel: WithdrawHubViewModel

    var body: some View {
        WithdrawHubContentView(
            isWithinPortfolioLoading: viewModel.isWithinPortfolioLoading,
            recentTokens: viewModel.recentTokens,
            recentAccounts: viewModel.recentAccounts,
            isSeeAllAccountsVisible: viewModel.isSeeAllAccountsVisible,
            bankTransferState: viewModel.bankTransferState,
            onAction: viewModel.handleViewAction
        )
        .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
        .alert(item: $viewModel.alert) { $0.alert }
        .topNavigation(
            title: Localization.tangempayWithdrawHubTitle,
            leading: .none,
            onClose: viewModel.onCloseTap
        )
    }
}
