//
//  PushNotificationsSyncWalletsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Provides synchronization of local wallet models with remote push-notification wallet state.
final class PushNotificationsSyncWalletsProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    func syncUserWalletModelState(applicationUid: String) async throws {
        let response = try await tangemApiService.getUserWallets(applicationUid: applicationUid)

        let uniqueEntries = Array(Set(response.map {
            ApplicationWalletEntry(id: $0.id, name: $0.name ?? "", notifyStatus: $0.notifyStatus)
        }))

        let toSyncEntries: [ApplicationWalletEntry]

        if hasWalletSetDivergedFromRemote(uniqueEntries) {
            toSyncEntries = try await connectUserWalletsIfNeeded(for: uniqueEntries)
        } else {
            toSyncEntries = uniqueEntries
        }

        for entry in toSyncEntries {
            try await syncUserWalletModel(with: entry)
        }
    }

    func handleSyncErrorForAllWallets() {
        for userWalletModel in userWalletRepository.models {
            userWalletModel.userTokensPushNotificationsManager.process(.walletsBindingInfoUnavailable)
        }
    }
}

// MARK: - Private

private extension PushNotificationsSyncWalletsProvider {
    var applicationUid: String {
        AppSettings.shared.applicationUid
    }

    func hasWalletSetDivergedFromRemote(_ remoteEntries: [ApplicationWalletEntry]) -> Bool {
        let localWalletIds = Set(userWalletRepository.models.map { $0.userWalletId.stringValue })
        let remoteWalletIds = Set(remoteEntries.map { $0.id })
        return localWalletIds != remoteWalletIds
    }

    func connectUserWalletsIfNeeded(for remoteEntries: [ApplicationWalletEntry]) async throws -> [ApplicationWalletEntry] {
        guard await AppSettings.shared.saveUserWallets else {
            try await connectWallets(walletIds: [])
            return []
        }

        let localWalletModels = userWalletRepository.models
        let remoteEntriesById = Dictionary(uniqueKeysWithValues: remoteEntries.map { ($0.id, $0) })

        try await connectWallets(walletIds: localWalletModels.map { $0.userWalletId.stringValue })

        var toSyncEntries: [ApplicationWalletEntry] = []

        for model in localWalletModels {
            let walletId = model.userWalletId.stringValue

            if let knownEntry = remoteEntriesById[walletId] {
                toSyncEntries.append(knownEntry)
            } else {
                let resolvedEntry = await resolveNewlyConnectedEntry(for: model)
                toSyncEntries.append(resolvedEntry)
            }
        }

        return toSyncEntries
    }

    /// Fetches fresh remote data for a wallet that was just connected. Falls back to a
    /// locally-derived entry if the remote fetch fails.
    func resolveNewlyConnectedEntry(for model: UserWalletModel) async -> ApplicationWalletEntry {
        let walletId = model.userWalletId.stringValue

        let notifyStatus = await model.userTokensPushNotificationsManager.getInitialPushStatusWithAllowance()

        if let remoteWallet = try? await tangemApiService.getUserWallet(userWalletId: walletId) {
            return ApplicationWalletEntry(
                id: remoteWallet.id,
                name: remoteWallet.name ?? "",
                notifyStatus: notifyStatus
            )
        }

        return ApplicationWalletEntry(
            id: walletId,
            name: model.name,
            notifyStatus: notifyStatus
        )
    }

    func syncUserWalletModel(with entry: ApplicationWalletEntry) async throws {
        guard let findUserWalletModel = userWalletRepository.models.first(where: {
            $0.userWalletId.stringValue == entry.id
        }) else {
            return
        }

        if findUserWalletModel.name != entry.name {
            findUserWalletModel.update(type: .newName(entry.name))
        }

        findUserWalletModel
            .userTokensPushNotificationsManager
            .process(.handleRemoteValue(entry.notifyStatus))
    }

    func connectWallets(walletIds: [String], shouldRetry: Bool = true) async throws {
        do {
            let request = ApplicationDTO.Connect.Request(walletIds: walletIds)
            try await tangemApiService.connectUserWallets(uid: applicationUid, requestModel: request)
        } catch let error as TangemAPIError where error.code == .badRequest {
            if shouldRetry {
                await createMissingWallets(walletIds: walletIds)
                try await connectWallets(walletIds: walletIds, shouldRetry: false)
            } else {
                PushNotificationsSyncServiceLogger.error("Failed to connect wallets after retry", error: error)
                throw error
            }
        } catch {
            PushNotificationsSyncServiceLogger.error("Failed to connect wallets", error: error)
            throw error
        }
    }

    func createMissingWallets(walletIds: [String]) async {
        await withTaskGroup { group in
            for walletId in walletIds {
                guard let model = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == walletId }) else {
                    continue
                }

                let helper = WalletCreationHelper(
                    userWalletId: model.userWalletId,
                    userWalletName: model.name,
                    userWalletConfig: model.config
                )

                group.addTask {
                    try? await helper.createWallet()
                }
            }

            await group.waitForAll()
        }
    }
}
