//
//  MCPIntentView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MCPIntentView<IntentProposalState: Equatable, IntentProposalContent: View>: View {
    @ObservedObject var viewModel: MCPIntentViewModel<IntentProposalState>
    @ViewBuilder let proposalContentBuilder: (MCPIntentProposalViewModel<IntentProposalState>) -> IntentProposalContent

    var body: some View {
        VStack(spacing: .zero) {
            FloatingSheetNavigationBarView(
                backgroundColor: Color.clear,
                closeButtonAction: { viewModel.handle(action: .navigationCloseButtonTapped) }
            )

            content
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .animation(Animation.mcpFloatingSheetFrameUpdate, value: viewModel.state)
        .onAppear {
            viewModel.handle(action: .viewDidAppear)
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
        case .issue(let issueViewModel):
            MCPIntentIssueView(viewModel: issueViewModel)
                .transition(AnyTransition.mcpContent)

        case .proposal(let proposalViewModel):
            proposalContentBuilder(proposalViewModel)
                .transition(AnyTransition.mcpContent)
        }
    }
}
