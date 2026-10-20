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
        .animation(.contentFrameUpdate, value: viewModel.state)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackground = .color(Colors.Background.tertiary)
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
            configuration.backgroundInteractionBehavior = .consumeTouches
        }
        .task {
            viewModel.handle(action: .viewDidLoad)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .proposal(let proposalViewModel):
            MCPConnectionRequestProposalView(viewModel: proposalViewModel, imageCache: imageCache)
                .transition(.content)

        case .userWalletSelector(let userWalletSelectorViewModel):
            MCPConnectionRequestUserWalletSelectorView(viewModel: userWalletSelectorViewModel)
                .transition(.content)

        case .agentConnected(let agentConnectedViewModel):
            MCPConnectionRequestAgentConnectedView(viewModel: agentConnectedViewModel)
                .transition(.content)
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
            closeButtonAction = { viewModel.handle(action: .closeButtonTapped) }

        case .userWalletSelector(let userWalletSelectorViewModel):
            title = userWalletSelectorViewModel.state.navigationTitle
            backButtonAction = { viewModel.handle(action: .backButtonTapped) }
            closeButtonAction = { viewModel.handle(action: .closeButtonTapped) }

        case .agentConnected:
            title = nil
            backButtonAction = nil
            closeButtonAction = { viewModel.handle(action: .closeButtonTapped) }
        }

        return FloatingSheetNavigationBarView(
            title: title,
            backgroundColor: Colors.Background.tertiary,
            bottomSeparatorLineIsVisible: false,
            backButtonAction: backButtonAction,
            closeButtonAction: closeButtonAction
        )
    }
}

extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}

private extension AnyTransition {
    static var content: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3).delay(0.2)),
            removal: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3))
        )
    }
}
