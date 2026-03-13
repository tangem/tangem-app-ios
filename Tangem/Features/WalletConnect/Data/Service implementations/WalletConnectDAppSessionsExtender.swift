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
    private let savedSessionMigrationService: WalletConnectSavedSessionMigrationService
    private let savedSessionToAccountsMigrationService: WalletConnectAccountMigrationService
    private let dAppSessionExtensionService: ReownWalletConnectDAppSessionExtensionService
    private let logger: TangemLogger.Logger
    private let currentDateProvider: () -> Date

    private var extendTask: Task<Void, Never>?

    init(
        connectedDAppRepository: some WalletConnectConnectedDAppRepository,
        savedSessionMigrationService: WalletConnectSavedSessionMigrationService,
        savedSessionToAccountsMigrationService: WalletConnectAccountMigrationService,
        dAppSessionExtensionService: ReownWalletConnectDAppSessionExtensionService,
        logger: TangemLogger.Logger,
        currentDateProvider: @escaping () -> Date = { Date() }
    ) {
        self.connectedDAppRepository = connectedDAppRepository
        self.savedSessionMigrationService = savedSessionMigrationService
        self.savedSessionToAccountsMigrationService = savedSessionToAccountsMigrationService
        self.dAppSessionExtensionService = dAppSessionExtensionService
        self.logger = logger
        self.currentDateProvider = currentDateProvider
    }

    func extendConnectedDAppSessionsIfNeeded() async {
        if let extendTask = extendTask {
            return await extendTask.value
        }

        let task = Task { [connectedDAppRepository, savedSessionMigrationService, savedSessionToAccountsMigrationService, logger, weak self] in
            do {
                let dAppsToExtend: [WalletConnectConnectedDApp]

                if FeatureProvider.isAvailable(.accounts) {
                    if let migratedDApps = try await savedSessionToAccountsMigrationService.migrateSavedSessionsToAccounts() {
                        dAppsToExtend = migratedDApps
                    } else {
                        dAppsToExtend = try await connectedDAppRepository.getAllDApps()
                    }
                } else {
                    if let migratedDApps = try await savedSessionMigrationService.migrateSavedSessions() {
                        dAppsToExtend = migratedDApps
                    } else {
                        dAppsToExtend = try await connectedDAppRepository.getAllDApps()
                    }
                }

                try await withCheckedThrowingContinuation { continuation in
                    Task {
                        await self?.extendDAppsWithTimeout(dAppsToExtend, continuation: continuation)
                    }
                }
            } catch {
                logger.error("Failed to extend connected dApps", error: error)
            }
        }

        extendTask = task

        return await task.value
    }

    // [REDACTED_TODO_COMMENT]
    private func extendDAppsWithTimeout(
        _ connectedDApps: [WalletConnectConnectedDApp],
        continuation: CheckedContinuation<Void, any Swift.Error>
    ) async {
        guard connectedDApps.isNotEmpty else {
            continuation.resume()
            return
        }

        let nonExpiredDApps = connectedDApps.filter {
            $0.session.expiryDate > currentDateProvider()
        }

        let gate = LockGate()

        await withTaskGroup(of: Void.self) { [weak self] taskGroup in
            guard let self else {
                gate.run { continuation.resume(returning: ()) }
                return
            }

            taskGroup.addTask {
                do {
                    let result = try await self.extend(connectedDApps: nonExpiredDApps)
                    try await self.handle(extendedDApps: result)
                    gate.run { continuation.resume(returning: ()) }
                } catch {
                    gate.run { continuation.resume(throwing: error) }
                }
            }

            taskGroup.addTask {
                do {
                    let nanoseconds = UInt64(Constants.extendTaskTimeout * Double(NSEC_PER_SEC))
                    try await Task.sleep(nanoseconds: nanoseconds)
                    gate.run { continuation.resume(throwing: Error.timeout) }
                } catch {
                    gate.run { continuation.resume(throwing: error) }
                }
            }

            defer { taskGroup.cancelAll() }
            await taskGroup.next()
        }
    }

    private func extend(connectedDApps: [WalletConnectConnectedDApp]) async throws -> [WalletConnectConnectedDApp] {
        guard connectedDApps.isNotEmpty else { return connectedDApps }

        return try await withThrowingTaskGroup(of: (Int, WalletConnectConnectedDApp?).self) { [weak self] taskGroup in
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
        try await dAppSessionExtensionService.extendSession(withTopic: connectedDApp.session.topic)

        let expiryDate = connectedDApp.session.expiryDate.advanced(by: Constants.extendedExpiryDateInSeconds)
        return connectedDApp.with(updatedExpiryDate: expiryDate)
    }

    private func handle(extendedDApps: [WalletConnectConnectedDApp]) async throws {
        try await connectedDAppRepository.replacingAllExistingDApps(with: extendedDApps)
    }
}

extension WalletConnectDAppSessionsExtender {
    @available(*, deprecated, message: "replace with general purpose forced-timeout function in https://tangem.atlassian.net/browse/[REDACTED_INFO]")
    private final class LockGate {
        private var isResumed = false
        private let lock = NSLock()

        func run(_ action: () -> Void) {
            lock.lock()
            defer { lock.unlock() }

            guard !isResumed else { return }
            isResumed = true
            action()
        }
    }

    private enum Error: Swift.Error {
        case timeout
    }

    private enum Constants {
        private static let extendedExpiryDateInDays = 7.0
        static let extendedExpiryDateInSeconds: TimeInterval = 60 * 60 * 24 * Self.extendedExpiryDateInDays

        static let extendTaskTimeout: TimeInterval = 10
    }
}

private extension WalletConnectConnectedDApp {
    func with(updatedExpiryDate: Date) -> WalletConnectConnectedDApp {
        switch self {
        case .v1(let dApp):
            return .v1(
                WalletConnectConnectedDAppV1(
                    session: WalletConnectDAppSession(
                        topic: dApp.session.topic,
                        namespaces: dApp.session.namespaces,
                        expiryDate: updatedExpiryDate
                    ),
                    userWalletID: dApp.userWalletID,
                    dAppData: dApp.dAppData,
                    verificationStatus: dApp.verificationStatus,
                    dAppBlockchains: dApp.dAppBlockchains,
                    connectionDate: dApp.connectionDate
                )
            )

        case .v2(let dApp):
            let wrapped = WalletConnectConnectedDAppV1(
                session: WalletConnectDAppSession(
                    topic: dApp.session.topic,
                    namespaces: dApp.session.namespaces,
                    expiryDate: updatedExpiryDate
                ),
                userWalletID: dApp.wrapped.userWalletID,
                dAppData: dApp.dAppData,
                verificationStatus: dApp.verificationStatus,
                dAppBlockchains: dApp.dAppBlockchains,
                connectionDate: dApp.connectionDate
            )
            return .v2(WalletConnectConnectedDAppV2(accountId: dApp.accountId, wrapped: wrapped))
        }
    }
}
