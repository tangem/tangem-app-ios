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
        tangemPayAccount: TangemPayAccount,
        recipient: TangemPayOfframpRecipient,
        savedRecipientName: String?,
        output: @escaping (TransferInputViewModel.Output) -> Void
    ) -> TransferInputViewModel {
        TransferInputViewModel(
            orderBuilder: orderBuilder,
            optionsRepository: CommonTangemPayOfframpOptionsRepository(
                customerService: tangemPayAccount.customerService
            ),
            accountTokensProvider: {
                await accountTokens(for: tangemPayAccount)
            },
            title: title(recipient: recipient, savedRecipientName: savedRecipientName),
            stepSubtitle: stepSubtitle(recipient: recipient),
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

    static func stepSubtitle(recipient: TangemPayOfframpRecipient) -> String? {
        switch recipient {
        case .saved:
            nil
        case .newIndividual:
            stepText(of: Constants.personalStepCount)
        case .newBusiness:
            stepText(of: Constants.businessStepCount)
        }
    }

    static func stepText(of total: Int) -> String {
        // [REDACTED_TODO_COMMENT]
        "1 of \(total)"
    }
}

// MARK: - Tokens

private extension TransferInputFactory {
    @MainActor
    static func accountTokens(for account: TangemPayAccount) async -> [TangemPayAccountToken] {
        if account.networks.isEmpty {
            await account.loadBalance()
        }

        return TangemPayAccountTokensResolver().resolve(networks: account.networks)
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
        static let personalStepCount = 4
        static let businessStepCount = 3
    }
}
