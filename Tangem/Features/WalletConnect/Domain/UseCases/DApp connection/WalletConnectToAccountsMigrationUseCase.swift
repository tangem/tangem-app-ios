//
//  WalletConnectToAccountsMigrationUseCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLogger

final class WalletConnectToAccountsMigrationUseCase {
    private let migrationService: WalletConnectAccountMigrationService
    private let logger: TangemLogger.Logger

    init(
        migrationService: WalletConnectAccountMigrationService,
        logger: TangemLogger.Logger
    ) {
        self.migrationService = migrationService
        self.logger = logger
    }

    func migrateIfNeeded() async throws(WalletConnectDAppPersistenceError) {
        logger.info("WalletConnect: Starting saved sessions migration to account scope")

        if let migratedDApps = try await migrationService.migrateSavedSessionsToAccounts() {
            logger.info("WalletConnect: Account scope migration completed with updates. Total sessions: \(migratedDApps.count)")
        } else {
            logger.debug("WalletConnect: Account scope migration completed without storage updates")
        }
    }
}
