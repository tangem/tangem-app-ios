//
//  WalletModelTransactionHistoryPublisherFactoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
@testable import Tangem
@testable import TangemExpress
@testable import BlockchainSdk

extension TransactionHistoryAuxDataRepositoryDependentTests {
    @Suite("Wallet model transaction history publisher factory", .timeLimit(.minutes(1)))
    final class WalletModelTransactionHistoryPublisherFactoryTests {
        @Test("An on-chain failure with nothing on screen yet reaches the list as an error, despite stored express records")
        func onChainFailureOnFirstLoadIsNotMaskedByExpressRecords() async {
            await withStubbedDependencies {
                let onChainState = CurrentValueSubject<WalletModelTransactionHistoryState, Never>(.loading)
                let (states, subscription) = Self.states(of: Self.makePublisher(onChainState: onChainState, exchangeStatus: .waiting))
                defer { subscription.cancel() }
                var iterator = states.makeAsyncIterator()

                guard case .loading? = await iterator.next() else {
                    Issue.record("The on-chain loading state is expected first")
                    return
                }

                onChainState.send(.error(TestError()))

                guard case .error? = await iterator.next() else {
                    Issue.record("The on-chain failure is expected to reach the list")
                    return
                }
            }
        }

        @Test("Express rows already on screen survive a failed on-chain refresh")
        func expressRowsOnScreenSurviveFailedRefresh() async {
            await withStubbedDependencies {
                let onChainState = CurrentValueSubject<WalletModelTransactionHistoryState, Never>(.loaded(items: []))
                let (states, subscription) = Self.states(of: Self.makePublisher(onChainState: onChainState, exchangeStatus: .waiting))
                defer { subscription.cancel() }
                var iterator = states.makeAsyncIterator()

                #expect(Self.loadedHashes(await iterator.next()) == [Self.syntheticHash])

                onChainState.send(.loading)
                onChainState.send(.error(TestError()))
                onChainState.send(.loaded(items: [Self.makeOnChainRecord(date: Self.dayAfterExchange)]))

                #expect(Self.loadedHashes(await iterator.next()) == [Self.onChainHash])
            }
        }

        @Test(
            "Express rows older than the loaded on-chain history are hidden, whatever the deal status",
            arguments: [ExpressTransactionStatus.refunded, .paused, .waiting, .failed]
        )
        func expressRowsOlderThanLoadedOnChainHistoryAreHidden(status: ExpressTransactionStatus) async {
            await withStubbedDependencies {
                let onChainState = CurrentValueSubject<WalletModelTransactionHistoryState, Never>(
                    .loaded(items: [Self.makeOnChainRecord(date: Self.dayAfterExchange)])
                )
                let (states, subscription) = Self.states(of: Self.makePublisher(onChainState: onChainState, exchangeStatus: status))
                defer { subscription.cancel() }
                var iterator = states.makeAsyncIterator()

                #expect(Self.loadedHashes(await iterator.next()) == [Self.onChainHash])
            }
        }

        @Test("Express rows within the loaded on-chain history stay visible")
        func expressRowsWithinLoadedOnChainHistoryStayVisible() async {
            await withStubbedDependencies {
                let onChainState = CurrentValueSubject<WalletModelTransactionHistoryState, Never>(
                    .loaded(items: [Self.makeOnChainRecord(date: Self.dayBeforeExchange)])
                )
                let (states, subscription) = Self.states(of: Self.makePublisher(onChainState: onChainState, exchangeStatus: .refunded))
                defer { subscription.cancel() }
                var iterator = states.makeAsyncIterator()

                #expect(Self.loadedHashes(await iterator.next()) == [Self.syntheticHash, Self.onChainHash])
            }
        }
    }
}

// MARK: - Helpers

private extension TransactionHistoryAuxDataRepositoryDependentTests.WalletModelTransactionHistoryPublisherFactoryTests {
    struct TestError: Error {}

    func withStubbedDependencies<T>(_ operation: () async throws -> T) async rethrows -> T {
        try await InjectedDependenciesIsolation.shared.run {
            let previousAuxDataRepository = InjectedValues[\.transactionHistoryAuxDataRepository]
            InjectedValues[\.transactionHistoryAuxDataRepository] = TransactionHistoryAuxDataRepositoryStub()
            defer { InjectedValues[\.transactionHistoryAuxDataRepository] = previousAuxDataRepository }
            return try await operation()
        }
    }

    static func makePublisher(
        onChainState: CurrentValueSubject<WalletModelTransactionHistoryState, Never>,
        exchangeStatus: ExpressTransactionStatus
    ) -> AnyPublisher<WalletModelTransactionHistoryState, Never> {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let wallet = Wallet(
            blockchain: token.blockchain,
            publicKey: .init(seedKey: Data(), derivationType: .none),
            addressesProvider: EmptyAddressesProvider()
        )
        let provider = StubTransactionHistoryProvider(records: [.express(.exchange(makeExchangeInfo(token: token, status: exchangeStatus)))])

        return WalletModelTransactionHistoryPublisherFactory.makeTransactionHistoryPublisher(
            transactionHistoryPublisher: onChainState,
            featuresPublisher: Just([.transactionHistory(provider: provider)]),
            walletModelId: WalletModelId(tokenItem: token),
            walletPublisher: Just(wallet),
            tokenItem: token,
            feeTokenItem: token
        )
    }

    static let exchangeTxId = "exchange-tx"
    static let onChainHash = "0xOnChainHash"
    static let syntheticHash = ExpressSyntheticTxHelper(txId: exchangeTxId).makeSyntheticTxIdentifier()
    static let dayAfterExchange = ExpressMergeTestDataFactory.baseDate.addingTimeInterval(ExpressMergeTestDataFactory.dayInSeconds)
    static let dayBeforeExchange = ExpressMergeTestDataFactory.baseDate.addingTimeInterval(-ExpressMergeTestDataFactory.dayInSeconds)

    static func states(
        of publisher: AnyPublisher<WalletModelTransactionHistoryState, Never>
    ) -> (AsyncStream<WalletModelTransactionHistoryState>, AnyCancellable) {
        let (stream, continuation) = AsyncStream<WalletModelTransactionHistoryState>.makeStream()
        let subscription = publisher.sink { continuation.yield($0) }
        return (stream, subscription)
    }

    static func loadedHashes(_ state: WalletModelTransactionHistoryState?) -> [String]? {
        guard case .loaded(let items)? = state else {
            return nil
        }

        return items.map(\.hash)
    }

    static func makeOnChainRecord(date: Date) -> TransactionRecord {
        ExpressMergeTestDataFactory.bsdkTransaction(
            hash: onChainHash,
            isOutgoing: false,
            sources: ["0xCounterparty"],
            destinations: [(ExpressMergeTestDataFactory.ownerAddress, 5)],
            date: date,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
    }

    static func makeExchangeInfo(token: TokenItem, status: ExpressTransactionStatus) -> ExchangeTransactionInfo {
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: exchangeTxId,
            status: status,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            fromAmount: 2,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        return ExchangeTransactionInfo(transaction: exchange, provider: nil, cryptoCurrencies: [:])
    }

    struct StubTransactionHistoryProvider: TransactionHistoryProviding {
        let id = UUID()
        let mappingQueue = DispatchQueue(label: "com.tangem.tests.StubTransactionHistoryProvider")
        let records: [TransactionHistoryRecordsReader.Record]

        var state: TransactionHistorySyncState { get async { .idle(.ready) } }
        var stateUpdates: AsyncStream<TransactionHistorySyncState> { AsyncStream { $0.finish() } }

        func syncInitial() async {}
        func syncDelta() async {}
        func syncUserInitiated(_ kind: UserInitiatedSyncKind) async {}

        func enrich(with transaction: SentSwapTransactionData) async {}
        func enrich(with transaction: SentOnrampTransactionData) async {}
        func enrich(with transaction: ExchangeTransaction) async {}
        func enrich(with transaction: OnrampTransaction) async {}

        func historyUpdates(
            for walletModelId: WalletModelId,
            walletModelAddressesPublisher: some Publisher<[String], Never>
        ) -> AsyncStream<[TransactionHistoryRecordsReader.Record]> {
            AsyncStream { [records] continuation in
                continuation.yield(records)
            }
        }
    }
}
