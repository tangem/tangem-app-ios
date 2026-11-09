//
//  PolymarketDepositConfigurationTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import TangemPolymarket

// MARK: - Builder code store

@Suite("Polymarket builder code store", .timeLimit(.minutes(1)))
struct PolymarketBuilderCodeStoreTests {
    private let host = URL(string: "https://api.tangem.org")!
    private let otherHost = URL(string: "https://api.dev.tangem.org")!
    private let day: TimeInterval = 24 * 60 * 60

    @Test("A stored code stays usable for the whole day the guide allows")
    func freshWithinADay() {
        let clock = makeClock()
        let store = PolymarketBuilderCodeStore(now: { clock.withLock { $0 } })

        store.store("0x01", forHost: host)

        #expect(store.code(forHost: host) == "0x01")

        clock.withLock { $0 += day - 1 }
        #expect(store.code(forHost: host) == "0x01")
    }

    @Test("At a day old the code is dropped so the caller refetches")
    func staleAfterADay() {
        let clock = makeClock()
        let store = PolymarketBuilderCodeStore(now: { clock.withLock { $0 } })

        store.store("0x01", forHost: host)
        clock.withLock { $0 += day }

        #expect(store.code(forHost: host) == nil)
    }

    @Test("A code cached against one environment is never handed to another")
    func codeIsKeyedByHost() {
        let store = PolymarketBuilderCodeStore()

        store.store("0xprod", forHost: host)

        #expect(store.code(forHost: host) == "0xprod")
        #expect(store.code(forHost: otherHost) == nil)
    }

    @Test("Switching environments back finds each host's own code")
    func hostsDoNotOverwriteEachOther() {
        let store = PolymarketBuilderCodeStore()

        store.store("0xprod", forHost: host)
        store.store("0xdev", forHost: otherHost)

        #expect(store.code(forHost: host) == "0xprod")
        #expect(store.code(forHost: otherHost) == "0xdev")
    }

    @Test("A clock that moved backwards drops the entry instead of trusting a future timestamp")
    func negativeAgeIsNotFresh() {
        let clock = makeClock()
        let store = PolymarketBuilderCodeStore(now: { clock.withLock { $0 } })

        store.store("0x01", forHost: host)
        clock.withLock { $0 -= 1 }

        #expect(store.code(forHost: host) == nil)
    }

    private func makeClock() -> OSAllocatedUnfairLock<Date> {
        OSAllocatedUnfairLock(initialState: Date(timeIntervalSince1970: 1_787_000_000))
    }
}

// MARK: - Builder code format

@Suite("Polymarket builder code format", .timeLimit(.minutes(1)))
struct PolymarketBuilderCodeTests {
    @Test(
        "The format the guide pins is 0x plus 64 hex digits",
        arguments: [
            ("0x0000000000000000000000000000000000000000000000000000000000000001", true),
            ("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", true),
            ("0x0000000000000000000000000000000000000000000000000000000000000000", true),
            ("0000000000000000000000000000000000000000000000000000000000000001", false),
            ("0x00000000000000000000000000000000000000000000000000000000000000001", false),
            ("0x000000000000000000000000000000000000000000000000000000000000000g", false),
            ("0X0000000000000000000000000000000000000000000000000000000000000001", false),
            ("", false),
            ("0x", false),
        ]
    )
    func builderCodeFormat(code: String, isWellFormed: Bool) {
        #expect(PolymarketBuilderCode.isWellFormed(code) == isWellFormed)
    }
}
