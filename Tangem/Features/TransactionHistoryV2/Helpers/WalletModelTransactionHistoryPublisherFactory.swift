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
        yieldContractAddressPublisher: some Publisher<String?, Never>,
        tokenItem: TokenItem,
        feeTokenItem: TokenItem,
        transactionHistoryFetcher: TransactionHistoryFetcher?,
        isJointAccountsAvailable: Bool
    ) -> AnyPublisher<WalletModelTransactionHistoryState, Never> {
        // Retained before the express merge: an emptied on-chain response would otherwise still produce a
        // shorter merged list, which is how the reported partial loss of rows happens.
        let transactionHistoryPublisher = transactionHistoryPublisher.retainingContent()

        let walletModelAddressesPublisher = walletPublisher
            .map { $0.addresses.map(\.value) }
            .combineLatest(yieldContractAddressPublisher) { walletAddresses, yieldContractAddress in
                yieldContractAddress.map { walletAddresses + [$0] } ?? walletAddresses
            }
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
                    feeTokenItem: feeTokenItem,
                    transactionHistoryFetcher: transactionHistoryFetcher,
                    isJointAccountsAvailable: isJointAccountsAvailable
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
        feeTokenItem: TokenItem,
        transactionHistoryFetcher: TransactionHistoryFetcher?,
        isJointAccountsAvailable: Bool
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
                let jointOperationEnricher = TransactionHistoryJointOperationEnricher(
                    currentToken: tokenItem,
                    feeTokenItem: feeTokenItem
                )

                // [REDACTED_TODO_COMMENT]
                var exchangeTransactions: [ExchangeTransaction] = []
                var onrampTransactions: [OnrampTransaction] = []
                var jointOperations: [JointOperationHistoryItem] = []
                for record in records.unique() { // One row per index entry, e.g. the yield contract and the wallet
                    switch record {
                    case .express(.exchange(let transactionInfo)):
                        exchangeTransactions.append(transactionInfo.transaction)
                    case .express(.onramp(let transactionInfo)):
                        onrampTransactions.append(transactionInfo.transaction)
                    case .jointOperation(let info) where isJointAccountsAvailable:
                        jointOperations.append(info.item)
                    case .jointOperation:
                        break
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
                    let oldestOnChainDate = bsdkTransactions.compactMap(\.date).min()
                    let visibleTransactions = oldestOnChainDate.map { oldestOnChainDate in
                        mergedTransactions.filter { ($0.date ?? .distantFuture) >= oldestOnChainDate }
                    } ?? mergedTransactions
                    let isOnChainHistoryFullyLoaded = !(transactionHistoryFetcher?.canFetchHistory ?? false)
                    let enrichedTransactions = enrich(
                        visibleTransactions,
                        with: jointOperations,
                        syntheticWindowStart: isOnChainHistoryFullyLoaded ? nil : oldestOnChainDate,
                        using: jointOperationEnricher
                    )
                    return .loaded(items: enrichedTransactions)
                case .notSupported:
                    // Merging can add synthetic transactions even without matching BSDK transactions.
                    let mergedTransactions = merge(
                        bsdkTransactions: [],
                        exchangeTransactions: exchangeTransactions,
                        onrampTransactions: onrampTransactions,
                        using: merger
                    )
                    let enrichedTransactions = enrich(
                        mergedTransactions,
                        with: jointOperations,
                        syntheticWindowStart: nil,
                        using: jointOperationEnricher
                    )
                    return enrichedTransactions.isEmpty ? transactionHistoryState : .loaded(items: enrichedTransactions)
                case .notLoaded, .loading, .error:
                    return transactionHistoryState
                }
            }
            .retainingContent()
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

    private static func enrich(
        _ transactions: [TransactionRecord],
        with jointOperations: [JointOperationHistoryItem],
        syntheticWindowStart: Date?,
        using enricher: TransactionHistoryJointOperationEnricher
    ) -> [TransactionRecord] {
        guard jointOperations.isNotEmpty else {
            return transactions
        }

        return enricher.enrich(transactions, with: jointOperations, syntheticWindowStart: syntheticWindowStart)
    }
}
