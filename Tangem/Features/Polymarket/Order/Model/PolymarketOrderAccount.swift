//
//  PolymarketOrderAccount.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets

struct PolymarketOrderAccount: Hashable {
    let name: String
    let icon: ImageType
}

// MARK: - The account the order spends from

extension PolymarketOrderAccount {
    init(accountModel: any PolymarketAccountModel) {
        self.init(
            name: accountModel.name,
            icon: AccountModelUtils.UI.standaloneIconAsset(from: accountModel.icon)
        )
    }
}
