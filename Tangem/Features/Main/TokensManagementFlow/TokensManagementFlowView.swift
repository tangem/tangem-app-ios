//
//  TokensManagementFlowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemUIUtils

struct TokensManagementFlowView: View {
    @ObservedObject var viewModel: TokensManagementFlowCoordinator

    private var isRedesignedAccountSelector: Bool {
        viewModel.state.isChooseAccount && viewModel.isAddAndOrganizeRedesignEnabled
    }

    var body: some View {
        TokensManagementFlowContainerView(
            state: viewModel.state.rawCaseValue,
            hidesHeader: viewModel.state.hidesContainerHeader,
            topPadding: isRedesignedAccountSelector ? .zero : 16,
            bottomPadding: viewModel.state.isChooser ? 16 : .zero,
            isRedesign: viewModel.isAddAndOrganizeRedesignEnabled,
            headerContent: { headerView },
            mainContent: { mainContentView }
        )
        .environment(\.isAddAndOrganizeRedesignEnabled, viewModel.isAddAndOrganizeRedesignEnabled)
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

    private var cancelButton: some View {
        TangemButton(
            content: .text(AttributedString(Localization.commonCancel)),
            action: viewModel.close
        )
        .setStyleType(.secondary)
        .setSize(.x12)
        .setCornerStyle(.rounded)
        .setHorizontalLayout(.infinity)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var mainContentView: some View {
        switch viewModel.state {
        case .chooser:
            TokensManagementChooserView(viewModel: viewModel)
        case .chooseAccount(let accountSelector):
            if viewModel.isAddAndOrganizeRedesignEnabled {
                VStack(spacing: 0) {
                    AccountSelectorView(viewModel: accountSelector, style: .addTokenRedesigned)

                    cancelButton
                }
            } else {
                AccountSelectorView(viewModel: accountSelector, style: .addAndManage)
            }
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
