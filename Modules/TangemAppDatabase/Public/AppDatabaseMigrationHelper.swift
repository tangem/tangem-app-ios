//
//  AppDatabaseMigrationHelper.swift
//  TangemAppDatabase
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Provides various app-specific logic required by data migrations of the database schema.
public protocol AppDatabaseMigrationHelper: Sendable {
    func expressSyncMetadataV3WalletID(fromV2UserWalletID userWalletID: String) -> String
}
