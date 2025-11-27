//
//  WCMultipleTransactionAlertViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class WCMultipleTransactionAlertViewModel: ObservableObject {
    @Published private(set) var state: WCTransactionAlertState

    private let primaryAction: () async throws -> Void
    private let secondaryAction: () -> Void
    private let backAction: () -> Void

    init(state: WCTransactionAlertState, input: WCMultipleTransactionAlertInput) {
        self.state = state
        primaryAction = input.primaryAction
        secondaryAction = input.secondaryAction
        backAction = input.backAction
    }

    @MainActor
    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .primaryButtonTapped:
            Task {
                state = .init(from: state, isLoading: true)
                try await primaryAction()
                state = .init(from: state, isLoading: false)
            }
        case .secondaryButtonTapped:
            secondaryAction()
        case .backButtonTapped:
            backAction()
        }
    }
}

extension WCMultipleTransactionAlertViewModel {
    enum ViewAction {
        case primaryButtonTapped
        case secondaryButtonTapped
        case backButtonTapped
    }
}
