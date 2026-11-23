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

    @State private var cancelButtonHeight: CGFloat = 0

    var body: some View {
        TokensManagementFlowContainerView(
            state: viewModel.state.rawCaseValue,
            hidesHeader: viewModel.state.hidesContainerHeader,
            topPadding: viewModel.state.isChooseAccount ? .zero : 16,
            bottomPadding: viewModel.state.isChooser ? 16 : .zero,
            headerContent: { headerView },
            mainContent: { mainContentView }
        )
        .environment(\.isInTokensManagementFlow, true)
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
        TangemUI.Button(
            label: Localization.commonCancel,
            accessibilityLabel: nil,
            action: viewModel.close
        )
        .styleType(.secondary(.default))
        .size(.x12)
        .horizontalLayout(.infinity)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var mainContentView: some View {
        switch viewModel.state {
        case .chooser:
            TokensManagementChooserView(viewModel: viewModel)
        case .chooseAccount(let accountPicker):
            ZStack(alignment: .bottom) {
                ScrollableAccountPickerView(viewModel: accountPicker)
                    .bottomContentInset(cancelButtonHeight)

                cancelButton
                    .readGeometry(\.size.height) { cancelButtonHeight = $0 }
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
            AddCustomTokenDerivationPathWriterView(viewModel: derivationPathWriterViewModel, style: .addTokenRedesigned)
        }
    }
}
