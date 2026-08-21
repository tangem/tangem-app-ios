//
//  ExpressTransactionBalanceUpdater.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol ExpressTransactionBalanceUpdater {
    func updateBalances(for records: [ExpressPendingTransactionRecord])
    func updateUnfinishedDestinationBalances(userWalletId: UserWalletId)
}

final class CommonExpressTransactionBalanceUpdater {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    @Injected(\.expressPendingTransactionsRepository)
    private var expressPendingTransactionsRepository: ExpressPendingTransactionRepository

    private let refreshedTransactionIds = OSAllocatedUnfairLock(initialState: Set<String>())

    private func withWalletModels(
        for tokens: [ExpressPendingTransactionRecord.TokenTxInfo],
        perform: @escaping ([any WalletModel]) -> Void
    ) {
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

            perform(walletModels)
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

// MARK: - ExpressTransactionBalanceUpdater protocol conformance

extension CommonExpressTransactionBalanceUpdater: ExpressTransactionBalanceUpdater {
    func updateBalances(for records: [ExpressPendingTransactionRecord]) {
        let tokens = records.flatMap { [$0.sourceTokenTxInfo, $0.destinationTokenTxInfo] }

        withWalletModels(for: tokens) { walletModels in
            for walletModel in walletModels {
                // A completed exchange affects the wallet the way an outgoing transaction does, and the
                // shared post-transaction refresh both waits out the propagation of the exchange across
                // the blockchain RPC nodes and resets the wallet manager update throttle before reading
                walletModel.updateAfterSendingTransaction(silent: true)
            }
        }
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

        withWalletModels(for: tokens) { walletModels in
            // Transaction history is loaded per wallet, a shared token keeps it to a single load
            let updateToken = UUID()

            for walletModel in walletModels {
                walletModel.startUpdateTask(silent: true, options: .balances, updateToken: updateToken)
            }
        }
    }
}
