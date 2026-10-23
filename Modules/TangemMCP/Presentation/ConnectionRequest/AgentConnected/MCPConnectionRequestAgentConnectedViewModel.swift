//
//  MCPConnectionRequestAgentConnectedViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

@MainActor
final class MCPConnectionRequestAgentConnectedViewModel: HashableObject {
    private let doneAction: () -> Void

    let state: MCPConnectionRequestAgentConnectedState

    init(doneAction: @escaping () -> Void, state: MCPConnectionRequestAgentConnectedState) {
        self.doneAction = doneAction
        self.state = state
    }

    func handle(action: MCPConnectionRequestAgentConnectedAction) {
        switch action {
        case .doneButtonTapped:
            doneAction()
        }
    }
}
