//
//  TransactionHistoryMapperGroupingTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk
@testable import Tangem

@Suite("TransactionHistoryMapper grouping (.dayThenMonth)")
struct TransactionHistoryMapperGroupingTests {
    private let calendar = Calendar.current
    private let currentMonthStart: Date
    private let dayA: Date
    private let dayB: Date
    private let prevMonthDate: Date
    private let prevPrevMonthDate: Date

    init() {
        currentMonthStart = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        dayA = currentMonthStart
        dayB = calendar.date(byAdding: .day, value: 1, to: currentMonthStart)!
        prevMonthDate = calendar.date(byAdding: .day, value: -5, to: currentMonthStart)!
        prevPrevMonthDate = calendar.date(byAdding: .day, value: -40, to: currentMonthStart)!
    }

    @Test("Current-month records bucket by day, sorted descending")
    func currentMonthRecordsBucketByDay() {
        let mapper = makeSUT()
        let items = mapper.mapTransactionListItem(
            from: [
                makeRecord(hash: "A", date: dayA),
                makeRecord(hash: "B1", date: dayB),
                makeRecord(hash: "B2", date: calendar.date(byAdding: .hour, value: 6, to: dayB)!),
            ],
            groupingStyle: .dayThenMonth
        )

        #expect(items.count == 2)
        #expect(items[0].items.map(\.hash).sorted() == ["B1", "B2"])
        #expect(items[1].items.map(\.hash) == ["A"])
        #expect(items.allSatisfy { $0.header.isNotEmpty })
    }

    @Test("Records older than current month bucket by month, sorted descending")
    func olderRecordsBucketByMonth() {
        let mapper = makeSUT()

        let items = mapper.mapTransactionListItem(
            from: [
                makeRecord(hash: "prev1", date: prevMonthDate),
                makeRecord(hash: "prev2", date: calendar.date(byAdding: .day, value: -2, to: prevMonthDate)!),
                makeRecord(hash: "prevPrev", date: prevPrevMonthDate),
            ],
            groupingStyle: .dayThenMonth
        )

        #expect(items.count == 2)
        #expect(items[0].items.map(\.hash).sorted() == ["prev1", "prev2"])
        #expect(items[1].items.map(\.hash) == ["prevPrev"])
        #expect(items.allSatisfy { $0.header.isNotEmpty })
    }

    @Test("Day sections precede older month sections in output ordering")
    func dayAndMonthSectionOrdering() {
        let mapper = makeSUT()

        let items = mapper.mapTransactionListItem(
            from: [
                makeRecord(hash: "prevPrev", date: prevPrevMonthDate),
                makeRecord(hash: "A", date: dayA),
                makeRecord(hash: "prev", date: prevMonthDate),
                makeRecord(hash: "B", date: dayB),
            ],
            groupingStyle: .dayThenMonth
        )

        #expect(items.count == 4)
        #expect(items.map { $0.items.map(\.hash) } == [["B"], ["A"], ["prev"], ["prevPrev"]])
        #expect(items.allSatisfy { $0.header.isNotEmpty })
    }

    @Test("Day-bucket headers are never empty (today/yesterday/older same-month)")
    func dayBucketHeadersAreNeverEmpty() {
        let mapper = makeSUT()
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        var dates = [today, yesterday]
        if let earlierSameMonth = calendar.date(byAdding: .day, value: -3, to: today),
           earlierSameMonth >= currentMonthStart {
            dates.append(earlierSameMonth)
        }

        let items = mapper.mapTransactionListItem(
            from: dates.enumerated().map { makeRecord(hash: "\($0.offset)", date: $0.element) },
            groupingStyle: .dayThenMonth
        )

        #expect(items.isNotEmpty)
        #expect(items.allSatisfy { $0.header.isNotEmpty })
    }
}

// MARK: - Helpers

private extension TransactionHistoryMapperGroupingTests {
    func makeSUT() -> Tangem.TransactionHistoryMapper {
        Tangem.TransactionHistoryMapper(
            currencySymbol: "ETH",
            addressesProvider: StubTransactionHistoryAddressesProvider(walletAddresses: ["0xSource"]),
            showSign: true,
            isToken: false
        )
    }

    func makeRecord(hash: String, date: Date) -> TransactionRecord {
        TransactionRecord(
            hash: hash,
            index: 0,
            source: .single(.init(address: "0xSource", amount: 1)),
            destination: .single(.init(address: .user("0xDestination"), amount: 1)),
            fee: Fee(Amount(type: .coin, currencySymbol: "ETH", value: 0, decimals: 18)),
            status: .confirmed,
            isOutgoing: true,
            type: .transfer,
            date: date,
            tokenTransfers: [],
            nonce: nil
        )
    }
}

// MARK: - Stubs

private struct StubTransactionHistoryAddressesProvider: WalletModelTransactionHistoryAddressesProvider {
    let walletAddresses: [String]
}
