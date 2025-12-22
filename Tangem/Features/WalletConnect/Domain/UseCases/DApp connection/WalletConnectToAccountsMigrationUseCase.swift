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
    private let connectedDAppRepository: WalletConnectConnectedDAppRepository
    private let userWalletRepository: UserWalletRepository
    private let appSettings: AppSettings
    private let logger: TangemLogger.Logger

    init(
        connectedDAppRepository: WalletConnectConnectedDAppRepository,
        userWalletRepository: UserWalletRepository,
        appSettings: AppSettings,
        logger: TangemLogger.Logger
    ) {
        self.connectedDAppRepository = connectedDAppRepository
        self.userWalletRepository = userWalletRepository
        self.appSettings = appSettings
        self.logger = logger
    }

    func migrateIfNeeded() async throws(WalletConnectDAppPersistenceError) {
        guard FeatureProvider.isAvailable(.accounts) else {
            logger.debug("WalletConnect: Accounts feature disabled, skipping sessions migration")
            return
        }

        guard await !appSettings.didMigrateWalletConnectToAccounts else {
            logger.debug("WalletConnect: Account sessions migration already completed")
            return
        }

        logger.info("WalletConnect: Starting saved sessions migration to account scope")

        let allDApps = try await connectedDAppRepository.getAllDApps()

        let v1DApps = allDApps.compactMap { dApp -> WalletConnectConnectedDAppV1? in
            if case .v1(let legacy) = dApp { return legacy }
            return nil
        }

        guard !v1DApps.isEmpty else {
            logger.debug("WalletConnect: No sessions require account migration")
            await MainActor.run {
                appSettings.didMigrateWalletConnectToAccounts = true
            }
            return
        }

        logger.info("WalletConnect: Migrating \(v1DApps.count) session(s) to account scope")

        var migratedDApps: [WalletConnectConnectedDApp] = []

        for dApp in v1DApps {
            if let migratedDApp = await migrateDApp(dApp) {
                migratedDApps.append(migratedDApp)
            }
        }

        let alreadyMigratedDApps = allDApps.filter {
            if case .v2 = $0 { return true }
            return false
        }

        let updatedDApps = migratedDApps + alreadyMigratedDApps

        try await connectedDAppRepository.replacingAllExistingDApps(with: updatedDApps)

        await MainActor.run {
            appSettings.didMigrateWalletConnectToAccounts = true
        }

        logger.info("WalletConnect: Successfully migrated \(migratedDApps.count) session(s) to account scope")
    }

    // MARK: - Private

    private func migrateDApp(_ dApp: WalletConnectConnectedDAppV1) async -> WalletConnectConnectedDApp? {
        let sessionAddresses = dApp.session.namespaces.flatMap { $0.value.accounts }.map { $0.address }

        guard let accountId = await resolveAccountId(from: sessionAddresses) else {
            logger.warning("WalletConnect: Could not resolve accountId for dApp \(dApp.dAppData.name)")
            return nil
        }

        return .v2(
            WalletConnectConnectedDAppV2(
                session: dApp.session,
                accountId: accountId,
                dAppData: dApp.dAppData,
                verificationStatus: dApp.verificationStatus,
                dAppBlockchains: dApp.dAppBlockchains,
                connectionDate: dApp.connectionDate
            )
        )
    }

    private func resolveAccountId(from sessionAddresses: [String]) async -> String? {
        let uniqueSessionAddresses = Set(sessionAddresses)
        for userWalletModel in userWalletRepository.models {
            for accountModel in userWalletModel.accountModelsManager.accountModels {
                let cryptoAccount = accountModel.firstAvailableStandard()
                let accountAddresses = cryptoAccount.walletModelsManager.walletModels.map(\.walletConnectAddress)

                if !uniqueSessionAddresses.isDisjoint(with: Set(accountAddresses)) {
                    return cryptoAccount.id.walletConnectIdentifierString
                }
            }
        }

        return nil
    }
}
