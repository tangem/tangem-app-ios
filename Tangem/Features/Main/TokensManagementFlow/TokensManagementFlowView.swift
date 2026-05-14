//
//  TokensManagementFlowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

struct TokensManagementFlowView: View {
    @ObservedObject var viewModel: TokensManagementFlowCoordinator

    var body: some View {
        TokensManagementFlowContainerView(
            state: viewModel.state.rawCaseValue,
            hidesHeader: viewModel.state.hidesContainerHeader,
            bottomPadding: viewModel.state.isChooser ? 16 : .zero,
            headerContent: { headerView },
            mainContent: { mainContentView }
        )
    }

    // MARK: - Sub Views

    private var headerView: some View {
        BottomSheetHeaderView(
            title: viewModel.state.title,
            leading: { leadingButton },
            trailing: { trailingButtons }
        )
    }

    @ViewBuilder
    private var leadingButton: some View {
        if viewModel.state.canGoBack {
            NavigationBarButton.back(action: viewModel.goBack)
        }
    }

    private var trailingButtons: some View {
        NavigationBarButton.close(action: viewModel.close)
    }

    @ViewBuilder
    private var mainContentView: some View {
        switch viewModel.state {
        case .chooser:
            TokensManagementChooserView(viewModel: viewModel)
        case .chooseAccount(let accountSelector):
            AccountSelectorView(viewModel: accountSelector, style: .addAndManage)
        case .organize(let organizeViewModel):
            OrganizeTokensView(viewModel: organizeViewModel, onCloseTap: viewModel.close)
        case .manage(let manageTokensViewModel):
            ManageTokensView(viewModel: manageTokensViewModel, style: .addAndManage)
        case .addCustomToken(let addCustomTokenViewModel):
            AddCustomTokenView(viewModel: addCustomTokenViewModel)
        case .networkSelector(let networkSelectorViewModel):
            AddCustomTokenNetworkSelectorView(viewModel: networkSelectorViewModel)
        case .derivationSelector(let derivationSelectorViewModel):
            AddCustomTokenDerivationPathSelectorView(viewModel: derivationSelectorViewModel)
        case .derivationPathWriter(let derivationPathWriterViewModel):
            AddCustomTokenDerivationPathWriterView(viewModel: derivationPathWriterViewModel)
        }
    }
}
