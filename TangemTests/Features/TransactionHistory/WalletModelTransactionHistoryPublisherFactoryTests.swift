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
import TangemFoundation
@testable import Tangem
@testable import TangemExpress
@testable import BlockchainSdk

extension TransactionHistoryAuxDataRepositoryDependentTests {
    @Suite("Wallet model transaction history publisher factory")
    final class WalletModelTransactionHistoryPublisherFactoryTests {
        @Test("An on-chain failure with nothing on screen yet reaches the list as an error, despite stored express records")
        func onChainFailureOnFirstLoadIsNotMaskedByExpressRecords() async throws {
            try await withStubbedDependencies {
                let onChainState = CurrentValueSubject<WalletModelTransactionHistoryState, Never>(.loading)
                let recorder = StateRecorder(Self.makePublisher(onChainState: onChainState))
                let initialState = await recorder.settledLastState()
                try #require(initialState == "loading")

                onChainState.send(.error(TestError()))

                let lastState = await recorder.settledLastState()
                #expect(lastState == "error")
            }
        }

        @Test("Express rows already on screen survive a failed on-chain refresh")
        func expressRowsOnScreenSurviveFailedRefresh() async throws {
            try await withStubbedDependencies {
                let onChainState = CurrentValueSubject<WalletModelTransactionHistoryState, Never>(.loaded(items: []))
                let recorder = StateRecorder(Self.makePublisher(onChainState: onChainState))
                let initialState = await recorder.settledLastState()
                try #require(initialState == "loaded(1)")

                onChainState.send(.loading)
                onChainState.send(.error(TestError()))

                let lastState = await recorder.settledLastState()
                #expect(lastState == "loaded(1)")
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
        onChainState: CurrentValueSubject<WalletModelTransactionHistoryState, Never>
    ) -> AnyPublisher<WalletModelTransactionHistoryState, Never> {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let wallet = Wallet(
            blockchain: token.blockchain,
            publicKey: .init(seedKey: Data(), derivationType: .none),
            addressesProvider: EmptyAddressesProvider()
        )
        let provider = StubTransactionHistoryProvider(records: [.express(.exchange(makeExchangeInfo(token: token)))])

        return WalletModelTransactionHistoryPublisherFactory.makeTransactionHistoryPublisher(
            transactionHistoryPublisher: onChainState,
            featuresPublisher: Just([.transactionHistory(provider: provider)]),
            walletModelId: WalletModelId(tokenItem: token),
            walletPublisher: Just(wallet),
            tokenItem: token,
            feeTokenItem: token
        )
    }

    static func makeExchangeInfo(token: TokenItem) -> ExchangeTransactionInfo {
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .waiting,
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

    final class StateRecorder {
        private let tags = OSAllocatedUnfairLock<[String]>(initialState: [])
        private var cancellable: AnyCancellable?

        init(_ publisher: AnyPublisher<WalletModelTransactionHistoryState, Never>) {
            cancellable = publisher.sink { [tags] state in
                tags.withLock { $0.append(Self.tag(for: state)) }
            }
        }

        func settledLastState() async -> String? {
            try? await Task.sleep(for: .milliseconds(500))
            return tags.withLock { $0.last }
        }

        private static func tag(for state: WalletModelTransactionHistoryState) -> String {
            switch state {
            case .notSupported: "notSupported"
            case .notLoaded: "notLoaded"
            case .loading: "loading"
            case .loaded(let items): "loaded(\(items.count))"
            case .error: "error"
            }
        }
    }
}
