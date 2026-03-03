//
//  AccountDetailsActionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum AccountDetailsActionsProvider {
    static func getAvailableActions(for account: any CryptoAccountModel) -> [AccountDetailsViewModel.Action] {
        [
            .edit,
            account.isMainAccount ? nil : .archive,
            .manageTokens,
        ].compactMap { $0 }
    }
}
