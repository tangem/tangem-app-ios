//
//  MCPConnectionRequestAgentConnectedViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

@MainActor
final class MCPConnectionRequestAgentConnectedViewModel: HashableObject {
    private let doneButtonAction: () -> Void

    let state: MCPConnectionRequestAgentConnectedState

    init(doneButtonAction: @escaping () -> Void, state: MCPConnectionRequestAgentConnectedState) {
        self.doneButtonAction = doneButtonAction
        self.state = state
    }

    func handle(action: MCPConnectionRequestAgentConnectedAction) {
        switch action {
        case .doneButtonTapped:
            doneButtonAction()
        }
    }
}
