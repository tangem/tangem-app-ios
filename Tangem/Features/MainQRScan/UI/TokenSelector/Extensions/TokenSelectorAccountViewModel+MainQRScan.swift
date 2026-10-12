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
        items.filter(\.availabilityType.isAvailable)
    }

    var incompatibleItemsCount: Int {
        items.count(where: \.availabilityType.isUnavailable)
    }

    var hasCompatibleItems: Bool {
        items.contains(where: \.availabilityType.isAvailable)
    }
}
