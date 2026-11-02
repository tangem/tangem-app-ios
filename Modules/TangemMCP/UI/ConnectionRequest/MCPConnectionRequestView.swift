//
//  MCPConnectionRequestView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemUI
import TangemAssets

struct MCPConnectionRequestView: View {
    @ObservedObject var viewModel: MCPConnectionRequestViewModel
    let imageCache: Kingfisher.ImageCache

    var body: some View {
        ScrollView(.vertical) {
            content
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .safeAreaInset(edge: .top, spacing: .zero) {
            header
        }
        .scrollBounceBehavior(.basedOnSize)
        .animation(Animation.mcpFloatingSheetFrameUpdate, value: viewModel.state)
        .task {
            viewModel.handle(action: .viewDidLoad)
        }
        .floatingSheetConfiguration { configuration in
            configuration.sheetFrameUpdateAnimation = Animation.mcpFloatingSheetFrameUpdate
            configuration.sheetBackground = FloatingSheetConfiguration.Background.mcpFloatingSheet
            configuration.backgroundInteractionBehavior = .consumeTouches
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .proposal(let proposalViewModel):
            MCPConnectionRequestProposalView(viewModel: proposalViewModel, imageCache: imageCache)
                .transition(AnyTransition.mcpContent)

        case .userWalletSelector(let userWalletSelectorViewModel):
            MCPConnectionRequestUserWalletSelectorView(viewModel: userWalletSelectorViewModel)
                .transition(AnyTransition.mcpContent)

        case .agentConnected(let agentConnectedViewModel):
            MCPConnectionRequestAgentConnectedView(viewModel: agentConnectedViewModel)
                .transition(AnyTransition.mcpContent)
        }
    }

    private var header: some View {
        let title: String?
        let backButtonAction: (() -> Void)?
        let closeButtonAction: (() -> Void)?

        switch viewModel.state {
        case .proposal(let proposalViewModel):
            title = proposalViewModel.state.navigationTitle
            backButtonAction = nil
            closeButtonAction = { viewModel.handle(action: .navigationCloseButtonTapped) }

        case .userWalletSelector(let userWalletSelectorViewModel):
            title = userWalletSelectorViewModel.state.navigationTitle
            backButtonAction = { viewModel.handle(action: .navigationBackButtonTapped) }
            closeButtonAction = { viewModel.handle(action: .navigationCloseButtonTapped) }

        case .agentConnected:
            title = nil
            backButtonAction = nil
            closeButtonAction = { viewModel.handle(action: .navigationCloseButtonTapped) }
        }

        return FloatingSheetNavigationBarView(
            title: title,
            backgroundColor: DesignSystem.Color.bgPrimary,
            bottomSeparatorLineIsVisible: false,
            backButtonAction: backButtonAction,
            closeButtonAction: closeButtonAction
        )
    }
}
