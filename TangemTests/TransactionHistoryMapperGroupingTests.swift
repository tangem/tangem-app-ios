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

@Suite("TransactionHistoryMapper grouping")
struct TransactionHistoryMapperGroupingTests {
    private let calendar = Calendar.current
    private let currentMonthStart: Date
    private let dayA: Date
    private let dayB: Date
    private let prevMonthDate: Date
    private let prevPrevMonthDate: Date
    private let today: Date
    private let yesterday: Date

    init() {
        currentMonthStart = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        dayA = currentMonthStart
        dayB = calendar.date(byAdding: .day, value: 1, to: currentMonthStart)!
        prevMonthDate = calendar.date(byAdding: .day, value: -5, to: currentMonthStart)!
        prevPrevMonthDate = calendar.date(byAdding: .day, value: -40, to: currentMonthStart)!
        today = calendar.startOfDay(for: Date())
        yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
    }

    // MARK: - .dayThenMonth

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
        let todayDate = Date()
        let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: todayDate)!

        var dates = [todayDate, yesterdayDate]
        if let earlierSameMonth = calendar.date(byAdding: .day, value: -3, to: todayDate),
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

    // MARK: - .day

    @Test("Same-day records collapse into one section", arguments: [Tangem.TransactionHistoryMapper.DayFormatStyle.short, .long])
    func sameDayRecordsCollapse(format: Tangem.TransactionHistoryMapper.DayFormatStyle) {
        let mapper = makeSUT()
        let items = mapper.mapTransactionListItem(
            from: [
                makeRecord(hash: "A", date: today),
                makeRecord(hash: "B", date: calendar.date(byAdding: .hour, value: 2, to: today)!),
            ],
            groupingStyle: .day(format)
        )

        #expect(items.count == 1)
        #expect(items[0].items.map(\.hash).sorted() == ["A", "B"])
        #expect(items[0].header.isNotEmpty)
    }

    @Test("Short format header matches DateFormatter dateStyle .short")
    func shortFormatHeader() {
        let pastDate = calendar.date(byAdding: .day, value: -10, to: today)!
        let items = makeSUT().mapTransactionListItem(
            from: [makeRecord(hash: "A", date: pastDate)],
            groupingStyle: .day(.short)
        )

        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .short
        formatter.doesRelativeDateFormatting = true

        #expect(items.first?.header == formatter.string(from: pastDate))
    }

    @Test("Long format header matches DateFormatter dateStyle .long")
    func longFormatHeader() {
        let pastDate = calendar.date(byAdding: .day, value: -10, to: today)!
        let items = makeSUT().mapTransactionListItem(
            from: [makeRecord(hash: "A", date: pastDate)],
            groupingStyle: .day(.long)
        )

        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .long
        formatter.doesRelativeDateFormatting = true

        #expect(items.first?.header == formatter.string(from: pastDate))
    }

    @Test("Multi-day records produce separate sections sorted newest first", arguments: [Tangem.TransactionHistoryMapper.DayFormatStyle.short, .long])
    func multiDaySortedDescending(format: Tangem.TransactionHistoryMapper.DayFormatStyle) {
        let mapper = makeSUT()
        let items = mapper.mapTransactionListItem(
            from: [
                makeRecord(hash: "old", date: yesterday),
                makeRecord(hash: "new", date: today),
            ],
            groupingStyle: .day(format)
        )

        #expect(items.count == 2)
        #expect(items[0].items.map(\.hash) == ["new"])
        #expect(items[1].items.map(\.hash) == ["old"])
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
            date: date
        )
    }
}

// MARK: - Stubs

private struct StubTransactionHistoryAddressesProvider: WalletModelTransactionHistoryAddressesProvider {
    let walletAddresses: [String]
}
