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

final class MarketsStubGeoEligibilityService: GeoEligibilityService {
    let regionCode: String?

    init(geoIpRegionCode: String?) {
        regionCode = geoIpRegionCode
    }

    var isUK: Bool { regionCode?.caseInsensitiveCompare("gb") == .orderedSame }
    var isApplePayAllowed: Bool { true }

    func initialize() {}
    func fetchGeoIpRegionCode() async -> String? { regionCode }
}

struct MarketsCategoriesTestError: Error, Equatable {
    let id: String

    static let network = MarketsCategoriesTestError(id: "network")
    static let disk = MarketsCategoriesTestError(id: "disk")
}

// MARK: - Gecko categories fixtures

enum MarketsGeckoCategoriesFixture {
    static func category(
        id: String,
        name: String? = nil,
        marketCap: Decimal? = 1_000_000_000,
        featured: Bool = false,
        tokensCount: Int = 10
    ) -> MarketsDTO.GeckoCategories.Category {
        MarketsDTO.GeckoCategories.Category(
            id: id,
            name: name ?? id.capitalized,
            marketCap: marketCap,
            marketCapChange24h: nil,
            featured: featured,
            tokensCount: tokensCount
        )
    }

    static let smartContracts = category(id: "smart-contract-platform", name: "Smart Contract Platform", marketCap: 2_000_000_000_000, featured: true, tokensCount: 548)
    static let layer1 = category(id: "layer-1", name: "Layer 1 (L1)", marketCap: 1_900_000_000_000, featured: true, tokensCount: 296)
    static let bitcoinEcosystem = category(id: "bitcoin-ecosystem", name: "Bitcoin Ecosystem", marketCap: 1_600_000_000_000, tokensCount: 212)
    static let did = category(id: "decentralized-identifier-did", name: "DID", marketCap: 1_800_000_000, featured: true, tokensCount: 24)

    static let all = [smartContracts, layer1, bitcoinEcosystem, did]
}
