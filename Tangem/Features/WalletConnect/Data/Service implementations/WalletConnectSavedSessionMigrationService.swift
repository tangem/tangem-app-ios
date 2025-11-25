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
            throw Error.invalidDAppURL(legacySession.sessionInfo.dAppInfo.url)
        }

        async let verificationStatus = (try? await dAppVerificationService.verify(dAppDomain: dAppDomain)) ?? .unknownDomain
        async let dAppIcon = await dAppIconURLResolver.resolveURL(from: legacySession.sessionInfo.dAppInfo.iconLinks)

        let dAppData = WalletConnectDAppData(
            name: legacySession.sessionInfo.dAppInfo.name,
            domain: dAppDomain,
            icon: await dAppIcon
        )

        let dAppBlockchains = Set(legacySession.connectedBlockchains)
            .sorted(by: \.displayName)
            .map {
                // [REDACTED_USERNAME], since we do not have information whether a certain blockchain was required,
                // it is safer to assume that all legacy session blockchains are required.
                WalletConnectDAppBlockchain(blockchain: $0, isRequired: true)
            }

        // [REDACTED_USERNAME], we do not have information about namespaces for legacy sessions.
        // It will not be possible to update them during wallet_addEthereumChain method handling.
        // All other cases should be fine.
        let emptyNamespaces = [String: WalletConnectSessionNamespace]()

        return .v1(
            WalletConnectConnectedDAppV1(
                session: WalletConnectDAppSession(topic: legacySession.topic, namespaces: emptyNamespaces, expiryDate: Date()),
                userWalletID: userWalletModel.userWalletId.stringValue,
                dAppData: dAppData,
                verificationStatus: await verificationStatus,
                dAppBlockchains: dAppBlockchains,
                connectionDate: Date()
            )
        )
    }
}

extension WalletConnectSavedSessionMigrationService {
    enum Error: LocalizedError {
        case userWalletNotFound
        case invalidDAppURL(String)

        var errorDescription: String? {
            switch self {
            case .userWalletNotFound:
                "DApp session migration failed because user wallet was not found."

            case .invalidDAppURL(let rawDomainString):
                "DApp migration operation failed because domain string is not a valid URL. Raw value: \(rawDomainString)"
            }
        }
    }
}
