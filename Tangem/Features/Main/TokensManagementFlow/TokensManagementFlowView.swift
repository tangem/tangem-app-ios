//
//  TokensManagementFlowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct TokensManagementFlowView: View {
    @ObservedObject var viewModel: TokensManagementFlowViewModel

    var body: some View {
        TokensManagementFlowContainerView(
            state: viewModel.state.rawCaseValue,
            fillsAvailableHeight: viewModel.state.fillsAvailableHeight,
            hidesHeader: viewModel.state.hidesContainerHeader,
            verticalSwipeBehavior: .init(target: .sheet, threshold: 100),
            headerContent: { headerView },
            mainContent: { mainContentView }
        )
    }

    // MARK: - Sub Views

    private var headerView: some View {
        BottomSheetHeaderView(
            title: viewModel.state.title,
            trailing: { NavigationBarButton.close(action: viewModel.close) }
        )
    }

    @ViewBuilder
    private var mainContentView: some View {
        switch viewModel.state {
        case .chooser:
            TokensManagementChooserView(viewModel: viewModel)
        case .chooseAccount:
            placeholder(text: "Choose account placeholder", nextTitle: "Next", nextAction: viewModel.proceedToManage)
        case .organize(let organizeViewModel):
            OrganizeTokensView(viewModel: organizeViewModel, onCloseTap: viewModel.close)
        case .manage:
            placeholder(text: "Manage tokens placeholder", nextTitle: "Add custom token", nextAction: viewModel.openAddCustomToken)
        case .addCustomToken:
            placeholder(text: "Add custom token placeholder")
        }
    }

    private func placeholder(
        text: String,
        nextTitle: String? = nil,
        nextAction: (() -> Void)? = nil
    ) -> some View {
        VStack(spacing: 12) {
            Text(text)
                .style(Fonts.Regular.body, color: Colors.Text.secondary)
                .padding(.vertical, 40)

            if let nextTitle, let nextAction {
                Button(nextTitle, action: nextAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
