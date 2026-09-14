//
//  TransferInputFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

enum TransferInputFactory {
    @MainActor
    static func makeViewModel(
        orderBuilder: TangemPayOfframpOrderBuilder,
        optionsStore: TangemPayOfframpOptionsStore,
        recipient: TangemPayOfframpRecipient,
        savedRecipientName: String?,
        output: @escaping (TransferInputViewModel.Output) -> Void
    ) -> TransferInputViewModel {
        TransferInputViewModel(
            orderBuilder: orderBuilder,
            optionsStore: optionsStore,
            title: title(recipient: recipient, savedRecipientName: savedRecipientName),
            stepSubtitle: TangemPayOfframpWizardStep.amount.subtitle(for: recipient),
            output: output
        )
    }
}

// MARK: - Header

private extension TransferInputFactory {
    static func title(recipient: TangemPayOfframpRecipient, savedRecipientName: String?) -> String {
        switch recipient {
        case .saved:
            savedRecipientName ?? Constants.savedFallbackTitle
        case .newIndividual:
            Constants.personalTitle
        case .newBusiness:
            Constants.businessTitle
        }
    }
}

// MARK: - Constants

private extension TransferInputFactory {
    enum Constants {
        // [REDACTED_TODO_COMMENT]
        static let personalTitle = "To personal account"
        // [REDACTED_TODO_COMMENT]
        static let businessTitle = "To business account"
        // [REDACTED_TODO_COMMENT]
        static let savedFallbackTitle = "Bank transfer"
    }
}
