//
//  WalletModelTransactionHistoryPublisherFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import BlockchainSdk
import TangemExpress
import TangemFoundation

enum WalletModelTransactionHistoryPublisherFactory {
    @Injected(\.transactionHistoryAuxDataRepository) private static var auxDataRepository: TransactionHistoryAuxDataRepository

    static func makeTransactionHistoryPublisher(
        transactionHistoryPublisher: some Publisher<WalletModelTransactionHistoryState, Never>,
        featuresPublisher: some Publisher<[WalletModelFeature], Never>,
        walletModelId: WalletModelId,
        walletPublisher: some Publisher<Wallet, Never>,
        tokenItem: TokenItem,
        feeTokenItem: TokenItem
    ) -> AnyPublisher<WalletModelTransactionHistoryState, Never> {
        guard FeatureProvider.isAvailable(.transactionHistoryV2) else {
            return transactionHistoryPublisher.eraseToAnyPublisher()
        }

        let walletModelAddressesPublisher = walletPublisher
            .map { $0.addresses.map(\.value) }
            .removeDuplicates()
            .eraseToAnyPublisher()

        return featuresPublisher
            .map(\.transactionHistoryProvider)
            .removeDuplicates { $0?.id.toAnyHashable() == $1?.id.toAnyHashable() }
            .flatMapLatest { provider -> AnyPublisher<WalletModelTransactionHistoryState, Never> in
                // No provider (unsupported chain) -> emit the unenriched on-chain history.
                guard let provider else {
                    return transactionHistoryPublisher.eraseToAnyPublisher()
                }

                return makeEnrichedPublisher(
                    from: transactionHistoryPublisher,
                    walletModelAddressesPublisher: walletModelAddressesPublisher,
                    provider: provider,
                    walletModelId: walletModelId,
                    tokenItem: tokenItem,
                    feeTokenItem: feeTokenItem
                )
            }
            .eraseToAnyPublisher()
    }

    /// Merges the on-chain history of a wallet model with the express records stored for it.
    private static func makeEnrichedPublisher(
        from originalTransactionHistoryPublisher: some Publisher<WalletModelTransactionHistoryState, Never>,
        walletModelAddressesPublisher: some Publisher<[String], Never>,
        provider: some TransactionHistoryProviding,
        walletModelId: WalletModelId,
        tokenItem: TokenItem,
        feeTokenItem: TokenItem
    ) -> AnyPublisher<WalletModelTransactionHistoryState, Never> {
        // [REDACTED_TODO_COMMENT]
        return originalTransactionHistoryPublisher
            .combineLatest(
                Publishers
                    .stream {
                        provider.historyUpdates(
                            for: walletModelId,
                            walletModelAddressesPublisher: walletModelAddressesPublisher
                        )
                    },
                Publishers
                    .stream {
                        auxDataRepository.didLoadAuxData
                    }
                    .prepend(()) // Emit an initial value in case the aux data is already cached and no updates are coming
            )
            .withLatestFrom(walletModelAddressesPublisher) { ($0.0, $0.1, $1) }
            .receive(on: provider.mappingQueue)
            .map { transactionHistoryState, records, walletModelAddresses in
                let merger = TransactionHistoryExpressDataMerger(
                    walletModelAddresses: walletModelAddresses,
                    currentToken: tokenItem,
                    feeTokenItem: feeTokenItem
                )

                // [REDACTED_TODO_COMMENT]
                var exchangeTransactions: [ExchangeTransaction] = []
                var onrampTransactions: [OnrampTransaction] = []
                for record in records {
                    switch record {
                    case .exchange(let transactionInfo):
                        exchangeTransactions.append(transactionInfo.transaction)
                    case .onramp(let transactionInfo):
                        onrampTransactions.append(transactionInfo.transaction)
                    }
                }

                switch transactionHistoryState {
                case .loaded(let bsdkTransactions):
                    let mergedTransactions = merge(
                        bsdkTransactions: bsdkTransactions,
                        exchangeTransactions: exchangeTransactions,
                        onrampTransactions: onrampTransactions,
                        using: merger
                    )
                    return .loaded(items: mergedTransactions)
                case .notSupported:
                    // The `.notSupported` state should be handled too, because merging can add synthetic transactions even without matching BSDK transactions.
                    let mergedTransactions = merge(
                        bsdkTransactions: [],
                        exchangeTransactions: exchangeTransactions,
                        onrampTransactions: onrampTransactions,
                        using: merger
                    )
                    return mergedTransactions.isEmpty ? .notSupported : .loaded(items: mergedTransactions)
                case .error,
                     .notLoaded,
                     .loading:
                    return transactionHistoryState
                }
            }
            .eraseToAnyPublisher()
    }

    private static func merge(
        bsdkTransactions: [TransactionRecord],
        exchangeTransactions: [ExchangeTransaction],
        onrampTransactions: [OnrampTransaction],
        using merger: TransactionHistoryExpressDataMerger
    ) -> [TransactionRecord] {
        ensureNotOnMainQueue()

        return merger.merge(
            bsdkTransactions: bsdkTransactions,
            exchangeTransactions: exchangeTransactions,
            onrampTransactions: onrampTransactions
        )
    }
}
