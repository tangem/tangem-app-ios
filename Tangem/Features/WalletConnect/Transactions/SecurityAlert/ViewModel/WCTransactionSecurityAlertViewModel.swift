//
//  WCTransactionSecurityAlertViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class WCTransactionSecurityAlertViewModel: ObservableObject {
    @Published private(set) var state: WCTransactionSecurityAlertState

    private let primaryAction: () -> Void
    private let secondaryAction: () async -> Void
    private let backAction: () -> Void

    init(state: WCTransactionSecurityAlertState, input: WCTransactionSecurityAlertInput) {
        self.state = state
        primaryAction = input.primaryAction
        secondaryAction = input.secondaryAction
        backAction = input.backAction
    }

    @MainActor
    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .primaryButtonTapped:
            primaryAction()
        case .secondaryButtonTapped:
            Task {
                state = .init(from: state, isLoading: true)
                await secondaryAction()
                state = .init(from: state, isLoading: false)
            }
        case .backButtonTapped:
            backAction()
        }
    }
}

extension WCTransactionSecurityAlertViewModel: Equatable {
    static func == (lhs: WCTransactionSecurityAlertViewModel, rhs: WCTransactionSecurityAlertViewModel) -> Bool {
        lhs.state == rhs.state
    }

    enum ViewAction {
        case primaryButtonTapped
        case secondaryButtonTapped
        case backButtonTapped
    }
}
