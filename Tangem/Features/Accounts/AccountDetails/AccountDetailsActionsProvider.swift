//
//  AccountDetailsActionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum AccountDetailsActionsProvider {
    static func getAvailableActions(for account: any BaseAccountModel) -> [AccountDetailsViewModel.Action] {
        switch account {
        case is any JointAccountModel:
            return [.archive, .manageTokens]

        case let cryptoAccount as any CryptoAccountModel:
            return [
                .edit,
                cryptoAccount.isMainAccount ? nil : .archive,
                .manageTokens,
            ].compactMap { $0 }

        default:
            assertionFailure("Unsupported account type: \(type(of: account))")
            return []
        }
    }
}
