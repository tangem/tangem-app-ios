//
//  FeeCurrencyNavigatingDismissOption.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct FeeCurrencyNavigatingDismissOption {
    let userWalletId: UserWalletId
    let tokenItem: TokenItem
}

// MARK: - Convenience init

extension FeeCurrencyNavigatingDismissOption {
    init(walletModel: some WalletModel) {
        userWalletId = walletModel.userWalletId
        tokenItem = walletModel.feeTokenItem
    }
}
