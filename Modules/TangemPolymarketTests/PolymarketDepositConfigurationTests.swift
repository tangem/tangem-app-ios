//
//  PolymarketDepositConfigurationTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Alamofire
import Moya
import TangemFoundation
@testable import TangemPolymarket

// MARK: - Configuration target

@Suite("Polymarket configuration target")
struct PolymarketConfigurationTargetTests {
    private let baseURL = URL(string: "https://api.tangem.org")!

    private func target(headers: [String: String] = [:], walletId: String = "abc") -> PolymarketConfigurationTarget {
        PolymarketConfigurationTarget(
            environment: PolymarketBFFEnvironment(baseURL: baseURL, headers: headers),
            walletId: walletId
        )
    }

    @Test("Path and method")
    func pathAndMethod() {
        #expect(target().baseURL == baseURL)
        #expect(target().path == "api/predictions/v1/configuration")
        #expect(target().method == .get)
    }

    @Test("The wallet id travels as a header, and the environment's own headers survive alongside it")
    func walletIdHeaderIsAddedToEnvironmentHeaders() {
        let walletId = String(repeating: "a", count: 64)
        let target = target(headers: ["api-key": "secret", "version": "6.4"], walletId: walletId)

        #expect(target.headers?["wallet-id"] == walletId)
        #expect(target.headers?["api-key"] == "secret")
        #expect(target.headers?["version"] == "6.4")
    }

    @Test("The configuration read takes no parameters")
    func requestIsPlain() {
        guard case .requestPlain = target().task else {
            Issue.record("The configuration read must be a plain request")
            return
        }
    }
}

// MARK: - Builder code store

@Suite("Polymarket builder code store")
struct PolymarketBuilderCodeStoreTests {
    private let host = URL(string: "https://api.tangem.org")!
    private let otherHost = URL(string: "https://api.dev.tangem.org")!
    private let day: TimeInterval = 24 * 60 * 60

    @Test("An empty store has nothing to hand out")
    func emptyStore() {
        #expect(PolymarketBuilderCodeStore().code(forHost: host) == nil)
    }

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

@Suite("Polymarket builder code format")
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
