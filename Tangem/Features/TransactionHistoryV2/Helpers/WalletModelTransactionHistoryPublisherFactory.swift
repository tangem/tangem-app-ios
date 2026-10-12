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

    private static let fallbackMappingQueue = DispatchQueue(
        label: "com.tangem.WalletModelTransactionHistoryPublisherFactory.fallbackMappingQueue",
        qos: .userInitiated,
        target: .global(qos: .userInitiated)
    )

    static func makeTransactionHistoryPublisher(
        transactionHistoryPublisher: some Publisher<WalletModelTransactionHistoryState, Never>,
        featuresPublisher: some Publisher<[WalletModelFeature], Never>,
        walletModelId: WalletModelId,
        walletPublisher: some Publisher<Wallet, Never>,
        tokenItem: TokenItem,
        feeTokenItem: TokenItem
    ) -> AnyPublisher<WalletModelTransactionHistoryState, Never> {
        // Retained before the express merge: an emptied on-chain response would otherwise still produce a
        // shorter merged list, which is how the reported partial loss of rows happens.
        let transactionHistoryPublisher = transactionHistoryPublisher.retainingContent()

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
                makeEnrichedPublisher(
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
        provider: (any TransactionHistoryProviding)?,
        walletModelId: WalletModelId,
        tokenItem: TokenItem,
        feeTokenItem: TokenItem
    ) -> AnyPublisher<WalletModelTransactionHistoryState, Never> {
        let expressRecords: AnyPublisher<[TransactionHistoryRecordsReader.Record], Never> = if let provider {
            Publishers
                .stream {
                    provider.historyUpdates(
                        for: walletModelId,
                        walletModelAddressesPublisher: walletModelAddressesPublisher
                    )
                }
                .eraseToAnyPublisher()
        } else {
            .just(output: [])
        }

        let combinedInput = originalTransactionHistoryPublisher
            .combineLatest(
                expressRecords,
                Publishers
                    .stream {
                        auxDataRepository.didLoadAuxData
                    }
            )
            .withLatestFrom(walletModelAddressesPublisher) { ($0.0, $0.1, $1) }

        return combinedInput
            .receive(on: provider?.mappingQueue ?? fallbackMappingQueue)
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
                case .notSupported, .error:
                    // Merging can add synthetic transactions even without matching BSDK transactions.
                    let mergedTransactions = merge(
                        bsdkTransactions: [],
                        exchangeTransactions: exchangeTransactions,
                        onrampTransactions: onrampTransactions,
                        using: merger
                    )
                    return mergedTransactions.isEmpty ? transactionHistoryState : .loaded(items: mergedTransactions)
                case .notLoaded, .loading:
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
