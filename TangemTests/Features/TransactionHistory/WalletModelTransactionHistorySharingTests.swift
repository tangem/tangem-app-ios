//
//  WalletModelTransactionHistorySharingTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import BlockchainSdk
import TangemFoundation
@testable import Tangem

extension TransactionHistoryAuxDataRepositoryDependentTests {
    @Suite("Wallet model transaction history sharing")
    final class WalletModelTransactionHistorySharingTests {
        @Test("A subscriber joining after a failed refresh starts from the list already on screen")
        func lateSubscriberGetsRetainedList() async throws {
            try await withStubbedDependencies {
                let service = StubTransactionHistoryService(records: [Self.makeRecord(hash: "0x1"), Self.makeRecord(hash: "0x2")])
                let walletModel = CommonWalletModel.previewWalletModel(transactionHistoryService: service)

                let list = StateRecorder(walletModel.transactionHistoryPublisher)
                let listState = try #require(await list.firstState(where: { $0.hasPrefix("loaded") }))

                service.failRefresh()

                let sheet = StateRecorder(walletModel.transactionHistoryPublisher)
                let sheetState = try #require(await sheet.firstState(where: { _ in true }))

                #expect(sheetState == listState)
            }
        }
    }
}

// MARK: - Helpers

private extension TransactionHistoryAuxDataRepositoryDependentTests.WalletModelTransactionHistorySharingTests {
    struct TestError: Error {}

    func withStubbedDependencies<T>(_ operation: () async throws -> T) async rethrows -> T {
        try await InjectedDependenciesIsolation.shared.run {
            let previousAuxDataRepository = InjectedValues[\.transactionHistoryAuxDataRepository]
            InjectedValues[\.transactionHistoryAuxDataRepository] = TransactionHistoryAuxDataRepositoryStub()
            defer { InjectedValues[\.transactionHistoryAuxDataRepository] = previousAuxDataRepository }
            return try await operation()
        }
    }

    final class StubTransactionHistoryService: TransactionHistoryService {
        private let stateSubject = CurrentValueSubject<TransactionHistoryServiceState, Never>(.loaded)
        private let records: OSAllocatedUnfairLock<[TransactionRecord]>

        init(records: [TransactionRecord]) {
            self.records = OSAllocatedUnfairLock(uncheckedState: records)
        }

        var state: TransactionHistoryServiceState { stateSubject.value }
        var statePublisher: AnyPublisher<TransactionHistoryServiceState, Never> { stateSubject.eraseToAnyPublisher() }
        var items: [TransactionRecord] { get async { records.withLockUnchecked { $0 } } }
        var canFetchHistory: Bool { false }

        func update() -> AnyPublisher<Void, Never> { .just(output: ()) }
        func clearHistory() async {}

        func failRefresh() {
            records.withLockUnchecked { $0.removeAll() }
            stateSubject.send(.loading)
            stateSubject.send(.failedToLoad(TestError()))
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

        func firstState(where predicate: (String) -> Bool, timeout: Duration = .seconds(2)) async -> String? {
            let deadline = ContinuousClock.now + timeout
            while ContinuousClock.now < deadline {
                if let tag = tags.withLock({ $0.first(where: predicate) }) {
                    return tag
                }
                try? await Task.sleep(for: .milliseconds(10))
            }
            return nil
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

    static func makeRecord(hash: String) -> TransactionRecord {
        ExpressMergeTestDataFactory.bsdkTransaction(
            hash: hash,
            isOutgoing: false,
            sources: ["0xCounterparty"],
            destinations: [(address: ExpressMergeTestDataFactory.ownerAddress, amount: 1)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
    }
}
