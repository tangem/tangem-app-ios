//
//  MarketsGeckoCategoriesDecodingTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("MarketsDTO.GeckoCategories decoding", .tags(.marketsCategories))
struct MarketsGeckoCategoriesDecodingTests {
    /// Trimmed from a live dev response on 2026-09-04; the `description` field is deliberately kept to prove it is skipped.
    private let payload = """
    {
      "categories": [
        {
          "id": "smart-contract-platform",
          "name": "Smart Contract Platform",
          "description": "Smart contract platforms are usually blockchains that host smart contracts.",
          "marketCap": 2198425453845.3564,
          "marketCapChange24h": 0.578110915421215,
          "volume24h": 52812175966.819016,
          "featured": true,
          "tokensCount": 548
        },
        {
          "id": "quantum-resistant",
          "name": "Quantum Resistant",
          "description": null,
          "marketCap": null,
          "marketCapChange24h": null,
          "volume24h": null,
          "featured": false,
          "tokensCount": 3
        }
      ],
      "total": 641,
      "offset": 0,
      "limit": 1000
    }
    """

    @Test("Decodes the live payload with the API service's snake-case decoder and tolerates null numbers")
    func decodesLivePayload() throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let response = try decoder.decode(MarketsDTO.GeckoCategories.Response.self, from: Data(payload.utf8))

        #expect(response.categories.count == 2)

        let first = response.categories[0]
        #expect(first.id == "smart-contract-platform")
        #expect(first.name == "Smart Contract Platform")
        #expect(first.marketCap == Decimal(string: "2198425453845.3564"))
        #expect(first.featured)
        #expect(first.tokensCount == 548)

        let second = response.categories[1]
        #expect(second.marketCap == nil)
        #expect(second.marketCapChange24h == nil)
        #expect(!second.featured)
    }

    @Test("Round-trips through Codable, which is what the fallback cache relies on")
    func roundTripsForCache() throws {
        let original = MarketsGeckoCategoriesFixture.all
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode([MarketsDTO.GeckoCategories.Category].self, from: data)

        #expect(decoded == original)
    }

    @Test("The request sends only the currency")
    func requestParameters() {
        let request = MarketsDTO.GeckoCategories.Request(currency: "EUR")

        #expect(request.parameters.count == 1)
        #expect(request.parameters["currency"] as? String == "EUR")
    }
}
