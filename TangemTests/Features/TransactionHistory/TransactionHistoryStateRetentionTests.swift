//
//  TransactionHistoryStateRetentionTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
@testable import Tangem
@testable import BlockchainSdk

@Suite("Transaction history state retention")
struct TransactionHistoryStateRetentionTests {
    @Test("Loading, a failure and an empty response never replace a list with transactions")
    func keepsContentAcrossFailedRefresh() {
        let states: [WalletModelTransactionHistoryState] = [
            .loaded(items: Self.records),
            .loading,
            .error(TestError()),
            .loaded(items: []),
        ]

        #expect(Self.tags(for: states) == ["loaded(2)"])
    }

    @Test("A refresh reset on chains with dynamic addresses does not replace a list with transactions")
    func keepsContentAcrossRefreshReset() {
        let states: [WalletModelTransactionHistoryState] = [
            .loaded(items: Self.records),
            .notLoaded,
            .loading,
            .error(TestError()),
        ]

        #expect(Self.tags(for: states) == ["loaded(2)"])
    }

    @Test("A response with transactions replaces the retained list")
    func replacesContentWithNewResponse() {
        let states: [WalletModelTransactionHistoryState] = [
            .loaded(items: Self.records),
            .loading,
            .loaded(items: Array(Self.records.prefix(1))),
        ]

        #expect(Self.tags(for: states) == ["loaded(2)", "loaded(1)"])
    }

    @Test("A chain that stops supporting history clears the retained list")
    func notSupportedClearsContent() {
        let states: [WalletModelTransactionHistoryState] = [
            .loaded(items: Self.records),
            .notSupported,
            .loaded(items: []),
        ]

        #expect(Self.tags(for: states) == ["loaded(2)", "notSupported", "loaded(0)"])
    }

    @Test("Nothing is held back while there are no transactions to keep")
    func passesEverythingWithoutContent() {
        let states: [WalletModelTransactionHistoryState] = [
            .notLoaded,
            .loading,
            .loaded(items: []),
            .error(TestError()),
            .loading,
        ]

        #expect(Self.tags(for: states) == ["notLoaded", "loading", "loaded(0)", "error", "loading"])
    }
}

// MARK: - Helpers

private extension TransactionHistoryStateRetentionTests {
    struct TestError: Error {}

    static var records: [TransactionRecord] {
        [makeRecord(hash: "0x1"), makeRecord(hash: "0x2")]
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

    static func tags(for states: [WalletModelTransactionHistoryState]) -> [String] {
        let subject = PassthroughSubject<WalletModelTransactionHistoryState, Never>()
        var received: [String] = []
        let cancellable = subject
            .retainingContent()
            .sink { received.append(tag(for: $0)) }

        states.forEach { subject.send($0) }
        cancellable.cancel()

        return received
    }

    static func tag(for state: WalletModelTransactionHistoryState) -> String {
        switch state {
        case .notSupported:
            return "notSupported"
        case .notLoaded:
            return "notLoaded"
        case .loading:
            return "loading"
        case .loaded(let items):
            return "loaded(\(items.count))"
        case .error:
            return "error"
        }
    }
}
