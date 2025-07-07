//
//  WCTransactionSecurityAlertViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct WCTransactionSecurityAlertViewModel {
    let state: WCTransactionSecurityAlertState
    private let primaryAction: () -> Void
    private let secondaryAction: () -> Void
    private let closeAction: () -> Void

    init(state: WCTransactionSecurityAlertState, input: WCTransactionSecurityAlertInput) {
        self.state = state
        primaryAction = input.primaryAction
        secondaryAction = input.secondaryAction
        closeAction = input.closeAction
    }

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .primaryButtonTapped:
            primaryAction()
        case .secondaryButtonTapped:
            secondaryAction()
        case .closeButtonTapped:
            closeAction()
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
        case closeButtonTapped
    }
}
