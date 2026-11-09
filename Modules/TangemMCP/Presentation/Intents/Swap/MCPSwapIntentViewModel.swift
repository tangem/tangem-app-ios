//
//  MCPSwapIntentViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import protocol TangemUI.FloatingSheetContentViewModel

@MainActor
public final class MCPSwapIntentViewModel: FloatingSheetContentViewModel {
    private let closeAction: () -> Void
    private let proceedAction: () -> Void

    let state: MCPSwapIntentState

    init(closeAction: @escaping () -> Void, proceedAction: @escaping () -> Void, state: MCPSwapIntentState) {
        self.closeAction = closeAction
        self.proceedAction = proceedAction
        self.state = state
    }

    func handle(action: MCPSwapIntentAction) {
        switch action {
        case .closeButtonTapped:
            closeAction()

        case .proceedButtonTapped:
            proceedAction()
        }
    }
}
