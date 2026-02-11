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

    func migrateSavedSessionsToAccounts() async throws(WalletConnectDAppPersistenceError) -> [WalletConnectConnectedDApp]? {
        let savedSessions: [WalletConnectConnectedDApp] = try await connectedDAppRepository.getAllDApps()

        guard savedSessions.isNotEmpty else {
            await setMigrationDone(true)
            return nil
        }

        var updatedDApps: [WalletConnectConnectedDApp] = []
        var hasChanges = false

        for savedSession in savedSessions {
            do {
                let migratedDApps = try await migrate(savedSession)
                if migratedDApps != [savedSession] {
                    hasChanges = true
                }
                updatedDApps.append(contentsOf: migratedDApps)
            } catch {
                WCLogger.warning("WalletConnect migration failed for topic: \(savedSession.session.topic). Keep original session. Error: \(error)")
                updatedDApps.append(savedSession)
            }
        }

        if hasChanges {
            try await connectedDAppRepository.replacingAllExistingDApps(with: updatedDApps)
        }

        let hasV1Sessions = containsLegacySessions(updatedDApps)
        await setMigrationDone(!hasV1Sessions)

        if !hasChanges {
            return nil
        }

        return updatedDApps
    }

    private func migrate(_ savedSession: WalletConnectConnectedDApp) async throws -> [WalletConnectConnectedDApp] {
        switch savedSession {
        case .v1(let legacyDApp):
            try await migrate(legacyDApp)
        case .v2(let accountScopedDApp):
            try await migrate(accountScopedDApp)
        }
    }

    private func migrate(_ legacyDApp: WalletConnectConnectedDAppV1) async throws -> [WalletConnectConnectedDApp] {
        let sessionAddresses = Set(
            legacyDApp.session.namespaces.flatMap { $0.value.accounts }.map { normalizeAddress($0.address) }
        )

        guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == legacyDApp.userWalletID }) else {
            throw Error.userWalletNotFound
        }

        let migrationTargets = resolveMigrationTargets(from: legacyDApp, userWalletModel: userWalletModel)
        guard migrationTargets.isNotEmpty else {
            throw Error.accountNotFound
        }

        let selectedTargets = selectTargets(
            migrationTargets,
            for: sessionAddresses
        )
        guard selectedTargets.isNotEmpty, addressesAreFullyCovered(sessionAddresses, by: selectedTargets) else {
            throw Error.accountNotFound
        }

        let migratedDApps = selectedTargets.map { target in
            let sanitizedDApp = sanitizeNamespaces(in: legacyDApp, allowedNormalizedAddresses: target.allowedNormalizedAddresses)
            return WalletConnectConnectedDApp.v2(
                WalletConnectConnectedDAppV2(
                    accountId: target.accountId,
                    wrapped: sanitizedDApp
                )
            )
        }

        guard sessionAccountsArePreserved(original: legacyDApp, migrated: migratedDApps) else {
            throw Error.accountNotFound
        }

        return migratedDApps
    }

    private func migrate(_ accountScopedDApp: WalletConnectConnectedDAppV2) async throws -> [WalletConnectConnectedDApp] {
        try await migrate(accountScopedDApp.wrapped)
    }

    private func resolveMigrationTargets(
        from dApp: WalletConnectConnectedDAppV1,
        userWalletModel: any UserWalletModel
    ) -> [MigrationTarget] {
        let sessionAddresses = Set(dApp.session.namespaces.flatMap { $0.value.accounts }.map { normalizeAddress($0.address) })
        guard sessionAddresses.isNotEmpty else {
            return []
        }

        let cryptoAccounts = userWalletModel.accountModelsManager.cryptoAccountModels
        let candidates = cryptoAccounts.map { account -> MigrationTarget in
            let normalizedAddresses = Set(account.walletModelsManager.walletModels.map { normalizeAddress($0.walletConnectAddress) })
            let matchedAddressesCount = sessionAddresses.intersection(normalizedAddresses).count

            return MigrationTarget(
                accountId: account.id.walletConnectIdentifierString,
                normalizedAddresses: normalizedAddresses,
                matchedAddressesCount: matchedAddressesCount,
                isMainAccount: account.isMainAccount
            )
        }

        return candidates
            .filter { $0.matchedAddressesCount > 0 }
            .sorted { lhs, rhs in
                if lhs.isMainAccount != rhs.isMainAccount {
                    return lhs.isMainAccount && !rhs.isMainAccount
                }

                if lhs.matchedAddressesCount != rhs.matchedAddressesCount {
                    return lhs.matchedAddressesCount > rhs.matchedAddressesCount
                }

                return lhs.accountId < rhs.accountId
            }
    }

    private func selectTargets(
        _ targets: [MigrationTarget],
        for sessionAddresses: Set<String>
    ) -> [SelectedMigrationTarget] {
        guard sessionAddresses.isNotEmpty else {
            return []
        }

        var matchedAddressesByAccount: [String: Set<String>] = [:]

        for sessionAddress in sessionAddresses {
            let candidates = targets.filter { $0.normalizedAddresses.contains(sessionAddress) }

            guard let selectedTarget = selectBestTarget(from: candidates) else {
                return []
            }

            matchedAddressesByAccount[selectedTarget.accountId, default: []].insert(sessionAddress)
        }

        return matchedAddressesByAccount
            .compactMap { accountId, matchedAddresses in
                guard let target = targets.first(where: { $0.accountId == accountId }) else {
                    return nil
                }

                return SelectedMigrationTarget(
                    accountId: accountId,
                    allowedNormalizedAddresses: matchedAddresses,
                    matchedAddressesCount: target.matchedAddressesCount,
                    isMainAccount: target.isMainAccount
                )
            }
            .sorted { lhs, rhs in
                if lhs.isMainAccount != rhs.isMainAccount {
                    return lhs.isMainAccount && !rhs.isMainAccount
                }

                if lhs.matchedAddressesCount != rhs.matchedAddressesCount {
                    return lhs.matchedAddressesCount > rhs.matchedAddressesCount
                }

                return lhs.accountId < rhs.accountId
            }
    }

    private func selectBestTarget(from candidates: [MigrationTarget]) -> MigrationTarget? {
        candidates.min { lhs, rhs in
            if lhs.matchedAddressesCount != rhs.matchedAddressesCount {
                // Prefer the account with fewer matched session addresses to avoid collapsing multiple accounts into one.
                return lhs.matchedAddressesCount < rhs.matchedAddressesCount
            }

            if lhs.normalizedAddresses.count != rhs.normalizedAddresses.count {
                return lhs.normalizedAddresses.count < rhs.normalizedAddresses.count
            }

            if lhs.isMainAccount != rhs.isMainAccount {
                return !lhs.isMainAccount && rhs.isMainAccount
            }

            return lhs.accountId < rhs.accountId
        }
    }

    private func sanitizeNamespaces(
        in dApp: WalletConnectConnectedDAppV1,
        allowedNormalizedAddresses: Set<String>
    ) -> WalletConnectConnectedDAppV1 {
        guard allowedNormalizedAddresses.isNotEmpty else {
            return dApp
        }

        let sanitizedNamespaces = dApp.session.namespaces.mapValues { namespace in
            let filteredAccounts = namespace.accounts.filter { account in
                allowedNormalizedAddresses.contains(normalizeAddress(account.address))
            }

            return WalletConnectSessionNamespace(
                blockchains: namespace.blockchains,
                accounts: filteredAccounts,
                methods: namespace.methods,
                events: namespace.events
            )
        }

        let sanitizedSession = WalletConnectDAppSession(
            topic: dApp.session.topic,
            namespaces: sanitizedNamespaces,
            expiryDate: dApp.session.expiryDate
        )

        return WalletConnectConnectedDAppV1(
            session: sanitizedSession,
            userWalletID: dApp.userWalletID,
            dAppData: dApp.dAppData,
            verificationStatus: dApp.verificationStatus,
            dAppBlockchains: dApp.dAppBlockchains,
            connectionDate: dApp.connectionDate
        )
    }

    private func addressesAreFullyCovered(
        _ sessionAddresses: Set<String>,
        by targets: [SelectedMigrationTarget]
    ) -> Bool {
        let coveredSessionAddresses = targets.reduce(into: Set<String>()) { partialResult, target in
            partialResult.formUnion(target.allowedNormalizedAddresses)
        }

        return coveredSessionAddresses == sessionAddresses
    }

    private func sessionAccountsArePreserved(
        original: WalletConnectConnectedDAppV1,
        migrated: [WalletConnectConnectedDApp]
    ) -> Bool {
        let originalAccounts = normalizedSessionAccounts(from: original)
        let migratedAccounts = Set(
            migrated
                .flatMap(\.session.namespaces.values)
                .flatMap(\.accounts)
                .map(normalizedAccountIdentity)
        )

        return originalAccounts == migratedAccounts
    }

    private func normalizedSessionAccounts(from dApp: WalletConnectConnectedDAppV1) -> Set<String> {
        Set(
            dApp.session.namespaces
                .flatMap(\.value.accounts)
                .map(normalizedAccountIdentity)
        )
    }

    private func normalizedAccountIdentity(_ account: WalletConnectAccount) -> String {
        "\(account.namespace):\(account.reference):\(normalizeAddress(account.address))"
    }

    private func normalizeAddress(_ address: String) -> String {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let isEvmAddress = trimmedAddress.hasHexPrefix()
            && trimmedAddress.count == 42
            && trimmedAddress.dropFirst(2).allSatisfy(\.isHexDigit)

        return isEvmAddress ? trimmedAddress.lowercased() : trimmedAddress
    }

    private func containsLegacySessions(_ dApps: [WalletConnectConnectedDApp]) -> Bool {
        dApps.contains {
            if case .v1 = $0 { return true }
            return false
        }
    }

    private func setMigrationDone(_ isDone: Bool) async {
        await MainActor.run {
            appSettings.didMigrateWalletConnectToAccounts = isDone
        }
    }
}

extension WalletConnectAccountMigrationService {
    private struct MigrationTarget {
        let accountId: String
        let normalizedAddresses: Set<String>
        let matchedAddressesCount: Int
        let isMainAccount: Bool
    }

    private struct SelectedMigrationTarget {
        let accountId: String
        let allowedNormalizedAddresses: Set<String>
        let matchedAddressesCount: Int
        let isMainAccount: Bool
    }

    enum Error: LocalizedError {
        case userWalletNotFound
        case accountNotFound
        case invalidDAppURL(String)

        var errorDescription: String? {
            switch self {
            case .userWalletNotFound:
                "DApp session migration failed because user wallet was not found."

            case .accountNotFound:
                "DApp session migration failed because no matching account was found."

            case .invalidDAppURL(let rawDomainString):
                "DApp migration operation failed because domain string is not a valid URL. Raw value: \(rawDomainString)"
            }
        }
    }
}
