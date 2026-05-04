//
//  TokenSelectorAccountViewModel+MainQRScan.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension TokenSelectorAccountViewModel {
    var walletName: String {
        switch header {
        case .wallet(let walletName):
            return walletName
        case .account(_, let accountName):
            return accountName
        }
    }

    var compatibleItems: [TokenSelectorItemViewModel] {
        items.filter { $0.disabledReason == nil }
    }

    var incompatibleItemsCount: Int {
        items.count(where: { $0.disabledReason != nil })
    }

    var hasCompatibleItems: Bool {
        items.contains(where: { $0.disabledReason == nil })
    }
}
