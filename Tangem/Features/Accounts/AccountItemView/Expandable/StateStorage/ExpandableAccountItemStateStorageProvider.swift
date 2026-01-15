//
//  ExpandableAccountItemStateStorageProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Aggregated storage for expandable account item states for all user wallets and accounts, single instance per app.
protocol ExpandableAccountItemStateStorageProvider: Initializable {
    func makeStateStorage(for userWalletId: UserWalletId) -> ExpandableAccountItemStateStorage
}
