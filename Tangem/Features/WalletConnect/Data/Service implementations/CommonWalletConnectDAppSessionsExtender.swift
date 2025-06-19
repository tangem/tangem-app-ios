//
//  CommonWalletConnectDAppSessionsExtender.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class CommonWalletConnectDAppSessionsExtender: WalletConnectDAppSessionsExtender {
    private let connectedDAppRepository: any WalletConnectConnectedDAppRepository
    private let savedSessionMigrationService: WalletConnectSavedSessionMigrationService
    private let walletConnectService: any WCService

    @MainActor
    private var hasExtendedConnectedDAppsForThisLaunch = false

    init(
        connectedDAppRepository: some WalletConnectConnectedDAppRepository,
        savedSessionMigrationService: WalletConnectSavedSessionMigrationService,
        walletConnectService: some WCService
    ) {
        self.connectedDAppRepository = connectedDAppRepository
        self.savedSessionMigrationService = savedSessionMigrationService
        self.walletConnectService = walletConnectService
    }

    func extendConnectedDAppSessionsIfNeeded() {
        Task { [connectedDAppRepository, savedSessionMigrationService, weak self] in
            guard await self?.hasExtendedConnectedDAppsForThisLaunch == false else { return }

            await MainActor.run { [weak self] in self?.hasExtendedConnectedDAppsForThisLaunch = true }

            _ = try await connectedDAppRepository.getAllDApps()

            // [REDACTED_TODO_COMMENT]
            guard false else {
                return
            }

            let dAppsToExtend: [WalletConnectConnectedDApp]

            if let migratedDApps = try await savedSessionMigrationService.migrateSavedSessions() {
                dAppsToExtend = migratedDApps
            } else {
                dAppsToExtend = try await connectedDAppRepository.getAllDApps()
            }

            try await self?.extendDAppsWithTimeout(dAppsToExtend)
        }
    }

    private func extendDAppsWithTimeout(_ connectedDApps: [WalletConnectConnectedDApp]) async throws {
        try await withThrowingTaskGroup(of: [WalletConnectConnectedDApp]?.self) { [weak self] taskGroup in
            taskGroup.addTask {
                return try await self?.extend(connectedDApps: connectedDApps)
            }

            taskGroup.addTask {
                let nanoseconds = UInt64(Constants.extendTaskTimeout * Double(NSEC_PER_SEC))
                try await Task.sleep(nanoseconds: nanoseconds)
                return nil
            }

            let result = try await taskGroup.next()!
            taskGroup.cancelAll()
            try await self?.handleDAppsExtensionResult(result)
        }
    }

    private func extend(connectedDApps: [WalletConnectConnectedDApp]) async throws -> [WalletConnectConnectedDApp] {
        try await withThrowingTaskGroup(of: (Int, WalletConnectConnectedDApp?).self) { [weak self] taskGroup in
            var extendedDApps = [WalletConnectConnectedDApp?](repeating: nil, count: connectedDApps.count)

            for (index, connectedDApp) in connectedDApps.enumerated() {
                taskGroup.addTask {
                    let extendedDApp = try await self?.extend(connectedDApp: connectedDApp)
                    return (index, extendedDApp)
                }
            }

            for try await (index, extendedDApp) in taskGroup {
                extendedDApps[index] = extendedDApp
            }

            return extendedDApps.compactMap { $0 }
        }
    }

    private func extend(connectedDApp: WalletConnectConnectedDApp) async throws -> WalletConnectConnectedDApp {
        try await walletConnectService.extendSession(withTopic: connectedDApp.session.topic)

        let expiryDate = connectedDApp.session.expiryDate.advanced(by: Constants.extendedExpiryDateInSeconds)
        return connectedDApp.with(updatedExpiryDate: expiryDate)
    }

    private func handleDAppsExtensionResult(_ result: [WalletConnectConnectedDApp]?) async throws {
        guard let extendedDApps = result, extendedDApps.isNotEmpty else {
            // [REDACTED_TODO_COMMENT]
            return
        }

        try await connectedDAppRepository.replacingExistingDApps(with: extendedDApps)
    }
}

extension CommonWalletConnectDAppSessionsExtender {
    private enum Constants {
        private static let extendedExpiryDateInDays = 7.0
        static let extendedExpiryDateInSeconds: TimeInterval = 60 * 60 * 24 * Self.extendedExpiryDateInDays

        static let extendTaskTimeout: TimeInterval = 5
    }
}

private extension WalletConnectConnectedDApp {
    func with(updatedExpiryDate: Date) -> WalletConnectConnectedDApp {
        WalletConnectConnectedDApp(
            session: WalletConnectDAppSession(topic: session.topic, expiryDate: updatedExpiryDate),
            userWallet: userWallet,
            dAppData: dAppData,
            verificationStatus: verificationStatus,
            blockchains: blockchains,
            connectionDate: connectionDate
        )
    }
}
