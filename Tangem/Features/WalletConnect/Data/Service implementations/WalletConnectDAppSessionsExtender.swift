//
//  WalletConnectDAppSessionsExtender.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLogger

actor WalletConnectDAppSessionsExtender {
    private let connectedDAppRepository: any WalletConnectConnectedDAppRepository
    private let dAppSessionExtensionService: ReownWalletConnectDAppSessionExtensionService
    private let logger: TangemLogger.Logger
    private let currentDateProvider: () -> Date

    private var extendTask: Task<Void, Never>?

    init(
        connectedDAppRepository: some WalletConnectConnectedDAppRepository,
        dAppSessionExtensionService: ReownWalletConnectDAppSessionExtensionService,
        logger: TangemLogger.Logger,
        currentDateProvider: @escaping () -> Date = { Date() }
    ) {
        self.connectedDAppRepository = connectedDAppRepository
        self.dAppSessionExtensionService = dAppSessionExtensionService
        self.logger = logger
        self.currentDateProvider = currentDateProvider
    }

    func extendConnectedDAppSessionsIfNeeded() async {
        if let extendTask = extendTask {
            return await extendTask.value
        }

        let task = Task { [connectedDAppRepository, logger, weak self] in
            do {
                let dAppsToExtend = try await connectedDAppRepository.getAllDApps()
                try await self?.extendDAppsWithTimeout(dAppsToExtend)
            } catch {
                logger.error("Failed to extend connected dApps", error: error)
            }
        }

        extendTask = task

        return await task.value
    }

    private func extendDAppsWithTimeout(_ connectedDApps: [WalletConnectConnectedDApp]) async throws {
        guard connectedDApps.isNotEmpty else { return }

        let nonExpiredDApps = connectedDApps.filter {
            $0.session.expiryDate > currentDateProvider()
        }

        try await Task.run(withTimeout: .seconds(Constants.extendTaskTimeout)) { [weak self] in
            guard let result = try await self?.extend(connectedDApps: nonExpiredDApps) else { return }

            try await self?.handle(extendedDApps: result)
        }
    }

    private func extend(connectedDApps: [WalletConnectConnectedDApp]) async throws -> [WalletConnectConnectedDApp] {
        guard connectedDApps.isNotEmpty else { return connectedDApps }

        return try await TaskGroup
            .tryExecuteKeepingOrder(items: connectedDApps) { [weak self] connectedDApp in
                try await self?.extend(connectedDApp: connectedDApp)
            }
            .compactMap(\.self)
    }

    private func extend(connectedDApp: WalletConnectConnectedDApp) async throws -> WalletConnectConnectedDApp {
        try await dAppSessionExtensionService.extendSession(withTopic: connectedDApp.session.topic)

        let expiryDate = connectedDApp.session.expiryDate.advanced(by: Constants.extendedExpiryDateInSeconds)
        return connectedDApp.with(updatedExpiryDate: expiryDate)
    }

    private func handle(extendedDApps: [WalletConnectConnectedDApp]) async throws {
        try await connectedDAppRepository.replacingAllExistingDApps(with: extendedDApps)
    }
}

extension WalletConnectDAppSessionsExtender {
    private enum Constants {
        private static let extendedExpiryDateInDays = 7.0
        static let extendedExpiryDateInSeconds: TimeInterval = 60 * 60 * 24 * Self.extendedExpiryDateInDays

        static let extendTaskTimeout: TimeInterval = 10
    }
}

private extension WalletConnectConnectedDApp {
    func with(updatedExpiryDate: Date) -> WalletConnectConnectedDApp {
        WalletConnectConnectedDApp(
            accountId: accountId,
            session: WalletConnectDAppSession(
                topic: session.topic,
                namespaces: session.namespaces,
                expiryDate: updatedExpiryDate
            ),
            userWalletID: userWalletID,
            dAppData: dAppData,
            verificationStatus: verificationStatus,
            dAppBlockchains: dAppBlockchains,
            connectionDate: connectionDate
        )
    }
}
