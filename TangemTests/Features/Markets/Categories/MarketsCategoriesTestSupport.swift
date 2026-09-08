//
//  MarketsCategoriesTestSupport.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

/// Use this tag for all coin-category suites: @Suite(.tags(.marketsCategories))
extension Tag {
    @Tag static var marketsCategories: Self
}

// MARK: - Fixtures

enum MarketsCategoriesFixture {
    static func sector(
        id: Int,
        code: String,
        displayOrder: Int = 0,
        tokensCount: Int = 1
    ) -> MarketsDTO.Categories.Sector {
        MarketsDTO.Categories.Sector(
            id: id,
            code: code,
            displayName: code.capitalized,
            displayOrder: displayOrder,
            tokensCount: tokensCount
        )
    }

    static func category(
        id: Int,
        code: String,
        displayOrder: Int = 0,
        restricted: Bool = false,
        tokensCount: Int = 10,
        sectors: [MarketsDTO.Categories.Sector] = [],
        visible: Bool? = true
    ) -> MarketsDTO.Categories.Category {
        MarketsDTO.Categories.Category(
            id: id,
            code: code,
            displayName: code.capitalized,
            displayOrder: displayOrder,
            restricted: restricted,
            tokensCount: tokensCount,
            sectors: sectors,
            visible: visible
        )
    }

    static let umbrella = category(id: 3, code: MarketsCategoryCode.realWorldAssets, displayOrder: 0)
    static let commodities = category(id: 5, code: MarketsCategoryCode.commodities, displayOrder: 3)
    static let xstocks = category(id: 2, code: "xstocks", displayOrder: 1, restricted: true)
}

// MARK: - Stubs

/// Round-trips through `Codable` like the real storage does, so the suites also cover encoding of the cache entry.
final class InMemoryPersistentStorage: PersistentStorageProtocol {
    var storeError: Error?

    private let state = OSAllocatedUnfairLock(initialState: [String: Data]())

    func value<T: Decodable>(for key: PersistentStorageKey) throws -> T? {
        guard let data = state.withLock({ $0[key.path] }) else {
            return nil
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    func store(value: some Encodable, for key: PersistentStorageKey) throws {
        if let storeError {
            throw storeError
        }

        let data = try JSONEncoder().encode(value)
        state.withLock { $0[key.path] = data }
    }

    func remove(for key: PersistentStorageKey) throws {
        state.withLock { $0[key.path] = nil }
    }
}

final class MarketsStubGeoEligibilityService: GeoEligibilityService {
    private let regionCode: String?

    init(geoIpRegionCode: String?) {
        regionCode = geoIpRegionCode
    }

    var isUK: Bool { regionCode?.caseInsensitiveCompare("gb") == .orderedSame }
    var isApplePayAllowed: Bool { true }

    func initialize() {}
    func waitForGeoIpRegionIfNeeded() async {}
    func fetchGeoIpRegionCode() async -> String? { regionCode }
}

struct MarketsCategoriesTestError: Error, Equatable {
    let id: String

    static let network = MarketsCategoriesTestError(id: "network")
    static let disk = MarketsCategoriesTestError(id: "disk")
}
