//
//  MCPIntentProposalViewModel.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

@MainActor
final class MCPIntentProposalViewModel<IntentProposalState: Equatable>: HashableObject {
    private let proceedAction: () -> Void

    let state: IntentProposalState

    init(proceedAction: @escaping () -> Void, state: IntentProposalState) {
        self.proceedAction = proceedAction
        self.state = state
    }

    func handle(action: MCPIntentProposalAction) {
        switch action {
        case .proceedButtonTapped:
            proceedAction()
        }
    }
}
