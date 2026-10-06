//
//  CollectiblesAccountRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemCollectibles

@MainActor
protocol CollectiblesAccountRoutable: AnyObject {
    func openAddFunds(account: CollectiblesVaultUsdcAccount)
}
