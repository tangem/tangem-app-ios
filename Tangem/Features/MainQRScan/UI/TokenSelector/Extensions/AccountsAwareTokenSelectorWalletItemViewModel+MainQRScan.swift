//
//  AccountsAwareTokenSelectorWalletItemViewModel+MainQRScan.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension AccountsAwareTokenSelectorWalletItemViewModel {
    var hasMultipleAccounts: Bool {
        if case .accounts = viewType {
            return true
        }

        return false
    }

    var hasCompatibleItems: Bool {
        switch viewType {
        case .wallet(let wallet):
            return wallet.hasCompatibleItems
        case .accounts(_, let accounts):
            return accounts.contains(where: { $0.hasCompatibleItems })
        }
    }
}
