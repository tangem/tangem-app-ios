//
//  ExpressTransactionBalanceUpdater.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class ExpressTransactionBalanceUpdater {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    @Injected(\.expressPendingTransactionsRepository)
    private var expressPendingTransactionsRepository: ExpressPendingTransactionRepository

    private let refreshedTransactionIds = OSAllocatedUnfairLock(initialState: Set<String>())

    func updateBalances(for records: [ExpressPendingTransactionRecord]) {
        let tokens = records.flatMap { [$0.sourceTokenTxInfo, $0.destinationTokenTxInfo] }
        update(tokens: tokens, options: .full)
    }

    func updateUnfinishedDestinationBalances(userWalletId: UserWalletId) {
        let records = expressPendingTransactionsRepository.transactions.filter { record in
            !record.isHidden
                && record.provider.type.supportStatusTracking
                && !record.transactionStatus.isTerminated(branch: .swap)
                && record.destinationTokenTxInfo.userWalletId == userWalletId.stringValue
        }

        // An exchange that nothing polls keeps its non-terminal status indefinitely, so a record is
        // refreshed on the first appearance only, the way the wallet content is fetched once on Android
        let tokens = refreshedTransactionIds
            .withLock { ids in records.filter { ids.insert($0.expressTransactionId).inserted } }
            .map(\.destinationTokenTxInfo)

        update(tokens: tokens, options: .balances)
    }

    private func update(tokens: [ExpressPendingTransactionRecord.TokenTxInfo], options: WalletModelUpdateOptions) {
        guard tokens.isNotEmpty else {
            return
        }

        // Status polling delivers its results in the background, while the wallet and the account models
        // are a main thread bound state
        DispatchQueue.main.async { [self] in
            // Deduplicated by identity, `WalletModelId` is shared by the same token in different accounts
            var seen = Set<ObjectIdentifier>()
            let walletModels = tokens
                .flatMap(walletModels(for:))
                .filter { seen.insert(ObjectIdentifier($0)).inserted }

            // Transaction history is loaded per wallet, a shared token keeps it to a single load
            let updateToken = UUID()

            for walletModel in walletModels {
                walletModel.startUpdateTask(silent: true, options: options, updateToken: updateToken)
            }
        }
    }

    private func walletModels(for token: ExpressPendingTransactionRecord.TokenTxInfo) -> [any WalletModel] {
        // In the send with swap flow the destination is a plain address outside of the app
        guard
            let userWalletId = token.userWalletId,
            let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == userWalletId })
        else {
            return []
        }

        let walletModelId = WalletModelId(tokenItem: token.tokenItem)
        let walletModels = AccountWalletModelsAggregator
            .walletModels(from: userWalletModel.accountModelsManager)
            .filter { $0.id == walletModelId }

        // The same token can be added to several accounts, the transaction address tells them apart
        if let address = token.address,
           let addressedWalletModel = walletModels.first(where: { walletModel in
               walletModel.addresses.contains { $0.value.caseInsensitiveEquals(to: address) }
           }) {
            return [addressedWalletModel]
        }

        return walletModels
    }
}
