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

    private static let longDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.setLocalizedDateFormatFromTemplate("MMMMdy")
        f.doesRelativeDateFormatting = true
        return f
    }()

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.setLocalizedDateFormatFromTemplate("MMMM, y")
        return f
    }()

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
                makeRecord(date: dayA),
                makeRecord(date: dayB),
                makeRecord(date: calendar.date(byAdding: .hour, value: 6, to: dayB)!),
            ],
            groupingStyle: .dayThenMonth
        )

        #expect(items.count == 2)
        #expect(items[0].header == Self.longDateFormatter.string(from: calendar.startOfDay(for: dayB)))
        #expect(items[0].items.count == 2)
        #expect(items[1].header == Self.longDateFormatter.string(from: calendar.startOfDay(for: dayA)))
        #expect(items[1].items.count == 1)
    }

    @Test("Records older than current month bucket by month, sorted descending")
    func olderRecordsBucketByMonth() {
        let mapper = makeSUT()
        let prevMonthStart = calendar.dateInterval(of: .month, for: prevMonthDate)!.start
        let prevPrevMonthStart = calendar.dateInterval(of: .month, for: prevPrevMonthDate)!.start

        let items = mapper.mapTransactionListItem(
            from: [
                makeRecord(date: prevMonthDate),
                makeRecord(date: calendar.date(byAdding: .day, value: -2, to: prevMonthDate)!),
                makeRecord(date: prevPrevMonthDate),
            ],
            groupingStyle: .dayThenMonth
        )

        #expect(items.count == 2)
        #expect(items[0].header == Self.monthFormatter.string(from: prevMonthStart))
        #expect(items[0].items.count == 2)
        #expect(items[1].header == Self.monthFormatter.string(from: prevPrevMonthStart))
        #expect(items[1].items.count == 1)
    }

    @Test("Day sections precede older month sections in output ordering")
    func dayAndMonthSectionOrdering() {
        let mapper = makeSUT()
        let prevMonthStart = calendar.dateInterval(of: .month, for: prevMonthDate)!.start
        let prevPrevMonthStart = calendar.dateInterval(of: .month, for: prevPrevMonthDate)!.start

        let items = mapper.mapTransactionListItem(
            from: [
                makeRecord(date: prevPrevMonthDate),
                makeRecord(date: dayA),
                makeRecord(date: prevMonthDate),
                makeRecord(date: dayB),
            ],
            groupingStyle: .dayThenMonth
        )

        #expect(items.count == 4)
        #expect(items[0].header == Self.longDateFormatter.string(from: calendar.startOfDay(for: dayB)))
        #expect(items[1].header == Self.longDateFormatter.string(from: calendar.startOfDay(for: dayA)))
        #expect(items[2].header == Self.monthFormatter.string(from: prevMonthStart))
        #expect(items[3].header == Self.monthFormatter.string(from: prevPrevMonthStart))
    }
}

// MARK: - Helpers

private extension TransactionHistoryMapperGroupingTests {
    func makeSUT() -> Tangem.TransactionHistoryMapper {
        Tangem.TransactionHistoryMapper(
            currencySymbol: "ETH",
            walletAddresses: ["0xSource"],
            showSign: true,
            isToken: false
        )
    }

    func makeRecord(date: Date) -> TransactionRecord {
        TransactionRecord(
            hash: UUID().uuidString,
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
