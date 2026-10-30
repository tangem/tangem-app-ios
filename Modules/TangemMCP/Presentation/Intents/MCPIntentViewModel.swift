//
//  MCPIntentViewModel.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.UUID
public import protocol TangemUI.FloatingSheetContentViewModel

public typealias MCPSwapIntentViewModel = MCPIntentViewModel<MCPSwapIntentState>
public typealias MCPSendIntentViewModel = MCPIntentViewModel<MCPSendIntentState>
public typealias MCPIntentStatusViewModel = MCPIntentViewModel<MCPIntentStatusState>

@MainActor
public final class MCPIntentViewModel<State>: FloatingSheetContentViewModel {
    public let id: String

    private let closeAction: () -> Void
    private let primaryAction: () -> Void

    let state: State

    init(
        id: String = UUID().uuidString,
        closeAction: @escaping () -> Void,
        primaryAction: @escaping () -> Void,
        state: State
    ) {
        self.id = id
        self.closeAction = closeAction
        self.primaryAction = primaryAction
        self.state = state
    }

    func handle(action: MCPIntentAction) {
        switch action {
        case .closeButtonTapped:
            closeAction()

        case .primaryButtonTapped:
            primaryAction()
        }
    }
}
