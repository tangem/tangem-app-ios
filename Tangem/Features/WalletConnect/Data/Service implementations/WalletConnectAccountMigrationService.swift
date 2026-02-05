//
//  WalletConnectAccountMigrationService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class WalletConnectAccountMigrationService {
    private let userWalletRepository: any UserWalletRepository
    private let connectedDAppRepository: any WalletConnectConnectedDAppRepository
    private let appSettings: AppSettings

    init(
        userWalletRepository: any UserWalletRepository,
        connectedDAppRepository: any WalletConnectConnectedDAppRepository,
        appSettings: AppSettings
    ) {
        self.userWalletRepository = userWalletRepository
        self.connectedDAppRepository = connectedDAppRepository
        self.appSettings = appSettings
    }

    func migrateSavedSessionsToAccounts() async throws -> [WalletConnectConnectedDApp]? {
        guard await !appSettings.didMigrateWalletConnectToAccounts else {
            return nil
        }

        let savedSessions: [WalletConnectConnectedDApp] = try await connectedDAppRepository.getAllDApps()

        let sessionsToMigrate = savedSessions.filter {
            if case .v1 = $0 { return true }
            return false
        }

        guard sessionsToMigrate.isNotEmpty else {
            await MainActor.run {
                appSettings.didMigrateWalletConnectToAccounts = true
            }
            return nil
        }

        await MainActor.run {
            appSettings.didMigrateWalletConnectToAccounts = true
        }

        return try await withThrowingTaskGroup(
            of: (Int, WalletConnectConnectedDApp?).self
        ) { taskGroup in
            var migratedSessions = [WalletConnectConnectedDApp?](repeating: nil, count: sessionsToMigrate.count)

            for (index, legacySession) in sessionsToMigrate.enumerated() {
                taskGroup.addTask {
                    try Task.checkCancellation()
                    let connectedDApp = try await self.migrate(legacySession: legacySession)
                    return (index, connectedDApp)
                }
            }

            for try await (index, connectedDApp) in taskGroup {
                migratedSessions[index] = connectedDApp
            }

            let migrated = migratedSessions.compactMap { $0 }

            let alreadyMigrated = savedSessions.filter {
                if case .v2 = $0 { return true }
                return false
            }

            let updatedDApps = migrated + alreadyMigrated

            try await connectedDAppRepository.replacingAllExistingDApps(with: updatedDApps)

            return updatedDApps
        }
    }

    private func migrate(legacySession: WalletConnectConnectedDApp) async throws -> WalletConnectConnectedDApp {
        switch legacySession {
        case .v2:
            return legacySession

        case .v1(let dApp):
            guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == dApp.userWalletID }) else {
                throw Error.userWalletNotFound
            }

            guard let mainAccount = userWalletModel.accountModelsManager.cryptoAccountModels.first(where: \.isMainAccount) else {
                throw Error.accountNotFound
            }

            return .v2(WalletConnectConnectedDAppV2(accountId: mainAccount.id.walletConnectIdentifierString, wrapped: dApp))
        }
    }
}

extension WalletConnectAccountMigrationService {
    enum Error: LocalizedError {
        case userWalletNotFound
        case accountNotFound
        case invalidDAppURL(String)

        var errorDescription: String? {
            switch self {
            case .userWalletNotFound:
                "DApp session migration failed because user wallet was not found."

            case .accountNotFound:
                "DApp session migration failed because main account was not found."

            case .invalidDAppURL(let rawDomainString):
                "DApp migration operation failed because domain string is not a valid URL. Raw value: \(rawDomainString)"
            }
        }
    }
}
