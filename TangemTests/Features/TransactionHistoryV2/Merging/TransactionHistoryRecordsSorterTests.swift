//
//  TransactionHistoryRecordsSorterTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem
@testable import BlockchainSdk

@Suite("TransactionHistoryRecordsSorter")
struct TransactionHistoryRecordsSorterTests {
    @Test("Newer records come first and a record without a date goes on top")
    func datesDescendWithNilFirst() {
        let undated = makeRecord(hash: "0xA", date: nil)
        let newer = makeRecord(hash: "0xB", date: Self.day(2))
        let older = makeRecord(hash: "0xC", date: Self.day(1))

        let sorted = TransactionHistoryRecordsSorter.sorted([older, newer, undated])

        #expect(sorted.map(\.hash) == ["0xA", "0xB", "0xC"])
    }

    @Test("Within one date a higher nonce comes first and a missing nonce goes last")
    func noncesDescendWithNilLast() {
        let noNonce = makeRecord(hash: "0xA", nonce: nil)
        let low = makeRecord(hash: "0xB", nonce: 2)
        let high = makeRecord(hash: "0xC", nonce: 9)

        let sorted = TransactionHistoryRecordsSorter.sorted([noNonce, low, high])

        #expect(sorted.map(\.hash) == ["0xC", "0xB", "0xA"])
    }

    @Test("Within one nonce records go by hash, then by index")
    func hashesAscendThenIndices() {
        let sorted = TransactionHistoryRecordsSorter.sorted([
            makeRecord(hash: "0xB", index: 1),
            makeRecord(hash: "0xB", index: 0),
            makeRecord(hash: "0xA", index: 0),
        ])

        #expect(sorted.map(\.hash) == ["0xA", "0xB", "0xB"])
        #expect(sorted.map(\.index) == [0, 0, 1])
    }
}

// MARK: - Fixtures

private extension TransactionHistoryRecordsSorterTests {
    static func day(_ number: Int) -> Date {
        ExpressMergeTestDataFactory.baseDate.addingTimeInterval(Double(number) * ExpressMergeTestDataFactory.dayInSeconds)
    }

    func makeRecord(
        hash: String,
        index: Int = 0,
        date: Date? = ExpressMergeTestDataFactory.baseDate,
        nonce: Int? = 1
    ) -> TransactionRecord {
        ExpressMergeTestDataFactory.bsdkTransaction(
            hash: hash,
            isOutgoing: true,
            sources: ["0xowner"],
            destinations: [(address: "0xpool", amount: 1)],
            date: date,
            index: index,
            nonce: nonce,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
    }
}
