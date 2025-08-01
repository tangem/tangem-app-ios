//
//  WCRequestDetailsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UIKit

final class WCRequestDetailsViewModel: ObservableObject {
    let requestDetails: [WCTransactionDetailsSection]

    var isCopyButtonVisible: Bool {
        rawTransaction?.isNotEmpty == true
    }

    private let rawTransaction: String?
    private let backAction: () -> Void
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)

    init(input: WCRequestDetailsInput) {
        backAction = input.backAction
        rawTransaction = input.rawTransaction
        requestDetails = input.builder.makeRequestDetails()
    }

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .returnTransactionDetails:
            backAction()
        case .copy:
            guard let rawTransaction, rawTransaction.isNotEmpty else { return }

            UIPasteboard.general.string = rawTransaction
            heavyImpactGenerator.impactOccurred()
        }
    }
}

extension WCRequestDetailsViewModel {
    enum ViewAction {
        case returnTransactionDetails
        case copy
    }
}
