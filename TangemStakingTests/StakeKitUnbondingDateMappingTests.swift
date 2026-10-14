//
//  StakeKitUnbondingDateMappingTests.swift
//  TangemStakingTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemStaking

@Suite("StakeKit unbonding date mapping")
struct StakeKitUnbondingDateMappingTests {
    typealias SUT = StakeKitMapper

    private let startOfToday = Calendar.current.startOfDay(for: Date())

    @Test("The epoch date StakeKit sends for TON unstaking is dropped")
    func epochDateIsDropped() throws {
        #expect(try mapUnstaking(dateJSON: "0") == .unbonding(date: nil))
    }

    @Test("A missing date stays missing")
    func nullDateStaysNil() throws {
        #expect(try mapUnstaking(dateJSON: "null") == .unbonding(date: nil))
    }

    @Test("A date before today is dropped", arguments: [-1, -30 * 86400] as [TimeInterval])
    func pastDateIsDropped(offset: TimeInterval) throws {
        let date = startOfToday.addingTimeInterval(offset)

        #expect(try mapUnstaking(date: date) == .unbonding(date: nil))
    }

    @Test("A date from today onwards is kept", arguments: [0, 3 * 86400] as [TimeInterval])
    func todayOrFutureDateIsKept(offset: TimeInterval) throws {
        let date = startOfToday.addingTimeInterval(offset)

        #expect(try mapUnstaking(date: date) == .unbonding(date: date))
    }
}

// MARK: - Private helpers

private extension StakeKitUnbondingDateMappingTests {
    typealias Balance = StakeKitDTO.Balances.Response.Balance

    func mapUnstaking(date: Date) throws -> StakingBalanceType {
        try mapUnstaking(dateJSON: "\(date.timeIntervalSince1970)")
    }

    func mapUnstaking(dateJSON: String) throws -> StakingBalanceType {
        let json = """
        {
            "groupId": "group",
            "type": "unstaking",
            "amount": "1",
            "date": \(dateJSON),
            "pricePerShare": "1",
            "pendingActions": [],
            "token": {"network": "ton", "name": "Toncoin", "decimals": 9, "symbol": "TON"}
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let balance = try decoder.decode(Balance.self, from: Data(json.utf8))
        return try SUT().mapToBalanceType(from: balance)
    }
}
