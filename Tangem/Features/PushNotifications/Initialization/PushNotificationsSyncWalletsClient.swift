//
//  PushNotificationsSyncWalletsClient.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Synchronizes local wallet models with remote push-notification wallet state.
final class PushNotificationsSyncWalletsClient {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    func syncUserWalletModelState(applicationUid: String) async throws {
        let response = try await tangemApiService.getUserWallets(applicationUid: applicationUid)

        let arrayEntries = response.map {
            ApplicationWalletEntry(id: $0.id, name: $0.name ?? "", notifyStatus: $0.notifyStatus)
        }

        let uniqueEntries = Array(Set(arrayEntries))

        if isNeedUpdateEntryByUserWalletModelList(with: uniqueEntries) {
            await connectUserWalletsIfNeeded(for: uniqueEntries)
        } else {
            for entry in uniqueEntries {
                try await syncUserWalletModel(with: entry)
            }
        }
    }

    func handleSyncErrorForAllWallets() {
        for userWalletModel in userWalletRepository.models {
            userWalletModel.userTokensPushNotificationsManager.handleSyncError()
        }
    }
}

// MARK: - Private

private extension PushNotificationsSyncWalletsClient {
    var applicationUid: String {
        AppSettings.shared.applicationUid
    }

    func isNeedUpdateEntryByUserWalletModelList(with entries: [ApplicationWalletEntry]) -> Bool {
        let userWalletModels = userWalletRepository.models

        let toUpdateEntryIds = userWalletModels.map { $0.userWalletId.stringValue }
        let differenceEntries = Set(entries.map { $0.id }).symmetricDifference(Set(toUpdateEntryIds))

        return !differenceEntries.isEmpty
    }

    func connectUserWalletsIfNeeded(for entries: [ApplicationWalletEntry]) async {
        guard await AppSettings.shared.saveUserWallets else {
            await connectWallets(entries: [])
            return
        }

        let userWalletModels = userWalletRepository.models

        var toUpdateEntries: [ApplicationWalletEntry] = []

        for userWalletModel in userWalletModels {
            let notifyStatus = await userWalletModel.userTokensPushNotificationsManager
                .getInitialPushStatusWithAllowance()

            toUpdateEntries.append(
                ApplicationWalletEntry(
                    id: userWalletModel.userWalletId.stringValue,
                    name: userWalletModel.name,
                    notifyStatus: notifyStatus
                )
            )
        }

        let modelsById = Dictionary(uniqueKeysWithValues: userWalletModels.map { ($0.userWalletId.stringValue, $0) })

        await connectWallets(entries: toUpdateEntries)

        for entry in toUpdateEntries {
            modelsById[entry.id]?.userTokensPushNotificationsManager
                .handleUpdateOnRemoteStatus(entry.notifyStatus)
        }
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
            .handleUpdateOnRemoteStatus(entry.notifyStatus)
    }

    func connectWallets(entries: [ApplicationWalletEntry], shouldRetry: Bool = true) async {
        do {
            let walletIds = entries.uniqueProperties(\.id)
            let request = ApplicationDTO.Connect.Request(walletIds: walletIds)
            try await tangemApiService.connectUserWallets(uid: applicationUid, requestModel: request)
        } catch let error as TangemAPIError where error.code == .badRequest {
            if shouldRetry {
                await createMissingWallets(entries: entries)
                await connectWallets(entries: entries, shouldRetry: false)
            } else {
                AppLogger.error(error: error)
            }
        } catch {
            // Do nothing. If the wallet is not connected to the app, it simply will not receive push messages, and you can try to connect it again.
            AppLogger.error(error: error)
        }
    }

    func createMissingWallets(entries: [ApplicationWalletEntry]) async {
        await withTaskGroup { group in
            for entry in entries {
                guard let model = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == entry.id }) else {
                    return
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
