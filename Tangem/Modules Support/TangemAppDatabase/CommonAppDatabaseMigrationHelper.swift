//
//  CommonAppDatabaseMigrationHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemAppDatabase

struct CommonAppDatabaseMigrationHelper {}

// MARK: - AppDatabaseMigrationHelper protocol conformance

extension CommonAppDatabaseMigrationHelper: AppDatabaseMigrationHelper {
    func expressSyncMetadataV3WalletID(fromV2UserWalletID userWalletID: String) -> String {
        let userWalletId = UserWalletId(stringValue: userWalletID)

        return TransactionHistorySyncMetadataUserWalletIDHasher.hash(userWalletId)
    }
}
