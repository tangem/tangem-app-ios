//
//  CommonMarketIndicatorsProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@Suite("CommonMarketIndicatorsProvider", .tags(.marketIndicators))
struct CommonMarketIndicatorsProviderTests {
    @Test("Asks for the selected currency in the device language")
    func sendsCurrencyAndLanguage() async throws {
        let requests = OSAllocatedUnfairLock(initialState: [MarketsDTO.MarketIndicators.Request]())
        let apiService = FakeTangemApiService()
        apiService.loadMarketIndicatorsHandler = { request in
            requests.withLock { $0.append(request) }
            return MarketIndicatorsFixture.response()
        }

        _ = try await CommonMarketIndicatorsProvider(apiService: apiService).indicators(currency: "EUR")

        let request = try #require(requests.withLock { $0.singleElement })
        #expect(request.currency == "EUR")
        #expect(request.language == Locale.deviceLanguageCode(withRegion: false))
        #expect(request.parameters as? [String: String] == ["currency": "EUR", "language": request.language])
    }

    @Test("Maps a full response into both readings")
    func mapsFullResponse() async throws {
        let indicators = try await indicators(from: MarketIndicatorsFixture.response())

        #expect(indicators.totalMarketCap == 3_500_000_000_000)
        #expect(indicators.marketCapChangePercentage24h == -1.25)
        #expect(indicators.fearGreed == MarketIndicators.Indicator(value: 52, classification: "Neutral"))
        #expect(indicators.altcoinIndex == MarketIndicators.Indicator(value: 30, classification: "Bitcoin Season"))
    }

    @Test("Keeps a reading whose classification the backend left out")
    func keepsReadingWithoutClassification() async throws {
        let response = MarketIndicatorsFixture.response(
            fearGreedClassification: nil,
            altcoinIndexClassification: ""
        )

        let indicators = try await indicators(from: response)

        #expect(indicators.fearGreed == MarketIndicators.Indicator(value: 52, classification: nil))
        #expect(indicators.altcoinIndex == MarketIndicators.Indicator(value: 30, classification: nil))
    }

    @Test("Drops a reading that came without a value, classification or not")
    func dropsReadingWithoutValue() async throws {
        let response = MarketIndicatorsFixture.response(fearGreedValue: nil, altcoinIndexValue: nil)

        let indicators = try await indicators(from: response)

        #expect(indicators.fearGreed == nil)
        #expect(indicators.altcoinIndex == nil)
    }

    @Test("Maps an empty response without inventing readings")
    func mapsEmptyResponse() async throws {
        let response = MarketIndicatorsFixture.response(
            totalMarketCap: nil,
            marketCapChangePercentage24H: nil,
            fearGreedValue: nil,
            fearGreedClassification: nil,
            altcoinIndexValue: nil,
            altcoinIndexClassification: nil
        )

        let indicators = try await indicators(from: response)

        #expect(indicators == MarketIndicators(totalMarketCap: nil, marketCapChangePercentage24h: nil, fearGreed: nil, altcoinIndex: nil))
    }

    @Test("Rethrows when the request fails")
    func rethrowsRequestFailure() async {
        let apiService = FakeTangemApiService()
        apiService.loadMarketIndicatorsHandler = { _ in throw MarketIndicatorsTestError.network }

        let provider = CommonMarketIndicatorsProvider(apiService: apiService)

        await #expect(throws: MarketIndicatorsTestError.network) {
            _ = try await provider.indicators(currency: "USD")
        }
    }

    // MARK: - Helpers

    private func indicators(from response: MarketsDTO.MarketIndicators.Response) async throws -> MarketIndicators {
        let apiService = FakeTangemApiService()
        apiService.loadMarketIndicatorsHandler = { _ in response }

        return try await CommonMarketIndicatorsProvider(apiService: apiService).indicators(currency: "USD")
    }
}
