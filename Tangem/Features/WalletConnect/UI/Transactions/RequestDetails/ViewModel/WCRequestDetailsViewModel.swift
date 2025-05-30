//
//  WCRequestDetailsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class WCRequestDetailsViewModel: ObservableObject {
    let requestDetails: [WCTransactionDetailsSection]

    private let backAction: () -> Void

    init(input: WCRequestDetailsInput) {
        backAction = input.backAction

        requestDetails = input.builder.makeRequestDetails()
    }

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .returnTransactionDetails:
            backAction()
        case .copy:
            // [REDACTED_TODO_COMMENT]
            break
        }
    }
}

// MARK: - ViewAction

extension WCRequestDetailsViewModel {
    enum ViewAction {
        case returnTransactionDetails
        case copy
    }
}
