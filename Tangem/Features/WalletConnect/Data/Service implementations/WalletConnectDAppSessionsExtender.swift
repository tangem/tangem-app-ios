//
//  WalletConnectDAppSessionsExtender.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

actor WalletConnectDAppSessionsExtender {
    private let connectedDAppRepository: any WalletConnectConnectedDAppRepository
    private let savedSessionMigrationService: WalletConnectSavedSessionMigrationService
    private let dAppSessionExtensionService: ReownWalletConnectDAppSessionExtensionService
    private let currentDateProvider: () -> Date

    private var extendTask: Task<Void, Never>?

    init(
        connectedDAppRepository: some WalletConnectConnectedDAppRepository,
        savedSessionMigrationService: WalletConnectSavedSessionMigrationService,
        dAppSessionExtensionService: ReownWalletConnectDAppSessionExtensionService,
        currentDateProvider: @escaping @autoclosure () -> Date = Date()
    ) {
        self.connectedDAppRepository = connectedDAppRepository
        self.savedSessionMigrationService = savedSessionMigrationService
        self.dAppSessionExtensionService = dAppSessionExtensionService
        self.currentDateProvider = currentDateProvider
    }

    func extendConnectedDAppSessionsIfNeeded() async {
        if let extendTask = extendTask {
            return await extendTask.value
        }

        let task = Task { [connectedDAppRepository, savedSessionMigrationService, weak self] in
            do {
                let dAppsToExtend: [WalletConnectConnectedDApp]

                if let migratedDApps = try await savedSessionMigrationService.migrateSavedSessions() {
                    dAppsToExtend = migratedDApps
                } else {
                    dAppsToExtend = try await connectedDAppRepository.getAllDApps()
                }

                try await withCheckedThrowingContinuation { continuation in
                    Task {
                        await self?.extendDAppsWithTimeout(dAppsToExtend, continuation: continuation)
                    }
                }
            } catch {
                // [REDACTED_TODO_COMMENT]
            }
        }

        extendTask = task

        return await task.value
    }

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

        await withThrowingTaskGroup(of: Void.self) { [weak self] taskGroup in
            guard let self else {
                gate.run { continuation.resume() }
                return
            }

            taskGroup.addTask {
                let result = try await self.extend(connectedDApps: nonExpiredDApps)
                try await self.handle(extendedDApps: result)
                gate.run { continuation.resume() }
            }

            taskGroup.addTask {
                let nanoseconds = UInt64(Constants.extendTaskTimeout * Double(NSEC_PER_SEC))
                try await Task.sleep(nanoseconds: nanoseconds)
                gate.run { continuation.resume(throwing: Error.timeout) }
            }

            defer { taskGroup.cancelAll() }
            _ = try? await taskGroup.next()
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
        try await connectedDAppRepository.replacingExistingDApps(with: extendedDApps)
    }
}

extension WalletConnectDAppSessionsExtender {
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
        WalletConnectConnectedDApp(
            session: WalletConnectDAppSession(topic: session.topic, expiryDate: updatedExpiryDate),
            userWalletID: userWalletID,
            dAppData: dAppData,
            verificationStatus: verificationStatus,
            blockchains: blockchains,
            connectionDate: connectionDate
        )
    }
}
