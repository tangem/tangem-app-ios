//
//  DefaultForceUpdateCacheTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("DefaultForceUpdateCache TTL")
struct DefaultForceUpdateCacheTests {
    @Test("Fresh entry (elapsed < ttl) is returned")
    func freshEntryReturned() {
        let clock = MutableClock(date: .init(timeIntervalSince1970: 1000))
        let cache = makeCache(ttl: 100, clock: clock)

        cache.dto = Self.dto
        clock.date = .init(timeIntervalSince1970: 1099) // elapsed 99 < 100

        #expect(cache.dto == Self.dto)
    }

    @Test("Entry at the ttl boundary (elapsed == ttl) is treated as stale")
    func boundaryEntryIsStale() {
        let clock = MutableClock(date: .init(timeIntervalSince1970: 1000))
        let cache = makeCache(ttl: 100, clock: clock)

        cache.dto = Self.dto
        clock.date = .init(timeIntervalSince1970: 1100) // elapsed 100 == ttl

        #expect(cache.dto == nil)
    }

    @Test("Stale entry (elapsed > ttl) is ignored")
    func staleEntryIgnored() {
        let clock = MutableClock(date: .init(timeIntervalSince1970: 1000))
        let cache = makeCache(ttl: 100, clock: clock)

        cache.dto = Self.dto
        clock.date = .init(timeIntervalSince1970: 5000) // way past ttl

        #expect(cache.dto == nil)
    }

    @Test("Empty storage returns nil")
    func emptyStorageReturnsNil() {
        let cache = makeCache(ttl: 100, clock: MutableClock(date: .init(timeIntervalSince1970: 1000)))
        #expect(cache.dto == nil)
    }

    @Test("Setting nil clears the cache")
    func settingNilClears() {
        let clock = MutableClock(date: .init(timeIntervalSince1970: 1000))
        let cache = makeCache(ttl: 100, clock: clock)

        cache.dto = Self.dto
        cache.dto = nil

        #expect(cache.dto == nil)
    }
}

// MARK: - Helpers

private extension DefaultForceUpdateCacheTests {
    static let dto = ApplicationVersionsDTO(
        criticalVersion: "6.1",
        criticalOSVersion: "27.0",
        minSupportedVersion: "6.0",
        minSupportedOSVersion: "26.0",
        latestVersion: "6.3"
    )

    func makeCache(ttl: TimeInterval, clock: MutableClock) -> DefaultForceUpdateCache {
        DefaultForceUpdateCache(
            storage: InMemoryBlockchainDataStorage(),
            ttl: ttl,
            now: { clock.date }
        )
    }
}

private final class MutableClock {
    var date: Date

    init(date: Date) {
        self.date = date
    }
}

private final class InMemoryBlockchainDataStorage: BlockchainDataStorage {
    private var values: [String: Data] = [:]

    func get<BlockchainData: Decodable>(key: String) -> BlockchainData? {
        decodedValue(forKey: key)
    }

    func get<BlockchainData: Decodable>(key: String) async -> BlockchainData? {
        decodedValue(forKey: key)
    }

    func store<BlockchainData: Encodable>(key: String, value: BlockchainData?) {
        encode(value, forKey: key)
    }

    func store<BlockchainData: Encodable>(key: String, value: BlockchainData?) async {
        encode(value, forKey: key)
    }

    private func decodedValue<BlockchainData: Decodable>(forKey key: String) -> BlockchainData? {
        values[key].flatMap { try? JSONDecoder().decode(BlockchainData.self, from: $0) }
    }

    private func encode(_ value: (some Encodable)?, forKey key: String) {
        guard let value else {
            values[key] = nil
            return
        }
        values[key] = try? JSONEncoder().encode(value)
    }
}
