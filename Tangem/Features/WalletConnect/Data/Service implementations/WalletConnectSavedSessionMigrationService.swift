//
//  WalletConnectConnectedDAppService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class WalletConnectSavedSessionMigrationService {
    private let sessionsStorage: any WalletConnectSessionsStorage
    private let userWalletRepository: any UserWalletRepository
    private let dAppVerificationService: any WalletConnectDAppVerificationService
    private let dAppIconURLResolver: WalletConnectDAppIconURLResolver
    private let appSettings: AppSettings

    init(
        sessionsStorage: any WalletConnectSessionsStorage,
        userWalletRepository: any UserWalletRepository,
        dAppVerificationService: any WalletConnectDAppVerificationService,
        dAppIconURLResolver: WalletConnectDAppIconURLResolver,
        appSettings: AppSettings
    ) {
        self.sessionsStorage = sessionsStorage
        self.userWalletRepository = userWalletRepository
        self.dAppVerificationService = dAppVerificationService
        self.dAppIconURLResolver = dAppIconURLResolver
        self.appSettings = appSettings
    }

    func migrateSavedSessions() async throws -> [WalletConnectConnectedDApp]? {
        guard await !appSettings.didMigrateWalletConnectSavedSessions else {
            return nil
        }

        let savedSessions: [WalletConnectSavedSession] = await sessionsStorage.getAllSessions()
        await sessionsStorage.removeAllSessions()

        await MainActor.run {
            appSettings.didMigrateWalletConnectSavedSessions = true
        }

        return try await withThrowingTaskGroup(
            of: (Int, WalletConnectConnectedDApp?).self
        ) { taskGroup in
            var connectedDApps = [WalletConnectConnectedDApp?](repeating: nil, count: savedSessions.count)

            for (index, legacySession) in savedSessions.enumerated() {
                taskGroup.addTask {
                    try Task.checkCancellation()
                    let connectedDApp = try await self.migrate(legacySession: legacySession)
                    return (index, connectedDApp)
                }
            }

            for try await (index, connectedDApp) in taskGroup {
                connectedDApps[index] = connectedDApp
            }

            return connectedDApps.compactMap { $0 }
        }
    }

    private func migrate(legacySession: WalletConnectSavedSession) async throws -> WalletConnectConnectedDApp {
        guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == legacySession.userWalletId }) else {
            throw Error.userWalletNotFound
        }

        guard let dAppDomain = URL(string: legacySession.sessionInfo.dAppInfo.url) else {
            throw Error.invalidDAppDomain
        }

        async let verificationStatus = (try? await dAppVerificationService.verify(dAppDomain: dAppDomain)) ?? .unknownDomain
        async let dAppIcon = await dAppIconURLResolver.resolveURL(from: legacySession.sessionInfo.dAppInfo.iconLinks)

        let dAppData = WalletConnectDAppData(
            name: legacySession.sessionInfo.dAppInfo.name,
            domain: dAppDomain,
            icon: await dAppIcon
        )

        return WalletConnectConnectedDApp(
            session: WalletConnectDAppSession(topic: legacySession.topic, expiryDate: Date()),
            userWalletID: userWalletModel.userWalletId.stringValue,
            dAppData: dAppData,
            verificationStatus: await verificationStatus,
            blockchains: Set(legacySession.connectedBlockchains).sorted(by: \.displayName),
            connectionDate: Date()
        )
    }
}

extension WalletConnectSavedSessionMigrationService {
    enum Error: Swift.Error {
        case userWalletNotFound
        case invalidDAppDomain
    }
}
