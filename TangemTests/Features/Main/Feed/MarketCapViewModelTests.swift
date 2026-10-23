//
//  MarketCapViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("MarketCapViewModel", .tags(.marketIndicators))
@MainActor
struct MarketCapViewModelTests {
    @Test("Shows the capitalisation, its 24h change and both readings")
    func showsFullBlock() async throws {
        let viewModel = makeViewModel(provider: StubMarketIndicatorsProvider(indicators: MarketIndicatorsFixture.indicators()))
        viewModel.onViewAppear()

        let content = try await content(of: viewModel)

        #expect(!content.totalMarketCap.isEmpty)
        #expect(content.priceChange.changeType == .negative)
        #expect(content.metrics.map(\.kind) == [.fearGreed, .altcoinIndex])
        #expect(content.metrics.map(\.status) == ["Neutral", "Bitcoin Season"])
        #expect(content.metrics.map(\.value) == ["52", "30"])
    }

    @Test("Hides the whole block when the capitalisation is missing or zero", arguments: [Decimal?]([nil, 0]))
    func hidesBlockWithoutCapitalisation(totalMarketCap: Decimal?) async throws {
        let indicators = MarketIndicatorsFixture.indicators(totalMarketCap: totalMarketCap)
        let viewModel = makeViewModel(provider: StubMarketIndicatorsProvider(indicators: indicators))
        viewModel.onViewAppear()

        _ = await waitUntilConditionMet { !viewModel.state.isLoading }

        #expect(viewModel.state.content == nil)
    }

    @Test("Keeps the headline when the backend omits a reading, dropping only its card")
    func dropsMissingReading() async throws {
        let indicators = MarketIndicatorsFixture.indicators(altcoinIndex: nil)
        let viewModel = makeViewModel(provider: StubMarketIndicatorsProvider(indicators: indicators))
        viewModel.onViewAppear()

        let content = try await content(of: viewModel)

        #expect(content.metrics.map(\.kind) == [.fearGreed])
    }

    /// A card without its classification has nothing to write under the title, and the backend never sends
    /// a value and a classification apart. Android drops such a reading in the same place.
    @Test("Drops a reading that arrived without its classification")
    func dropsReadingWithoutClassification() async throws {
        let indicators = MarketIndicatorsFixture.indicators(fearGreed: .init(value: 52, classification: nil))
        let viewModel = makeViewModel(provider: StubMarketIndicatorsProvider(indicators: indicators))
        viewModel.onViewAppear()

        let content = try await content(of: viewModel)

        #expect(content.metrics.map(\.kind) == [.altcoinIndex])
    }

    @Test("Asks again on the next appearance after a failed request")
    func retriesAfterFailure() async throws {
        let provider = StubMarketIndicatorsProvider(results: [
            .failure(MarketIndicatorsTestError.network),
            .success(MarketIndicatorsFixture.indicators()),
        ])
        let viewModel = makeViewModel(provider: provider)

        viewModel.onViewAppear()
        _ = await waitUntilConditionMet { !viewModel.state.isLoading }
        #expect(viewModel.state.content == nil)

        viewModel.onViewAppear()
        let content = try await content(of: viewModel)

        #expect(content.metrics.count == 2)
        #expect(provider.currencies.count == 2)
    }

    @Test("Does not repeat the request while the reading is still fresh")
    func keepsAFreshReading() async throws {
        let provider = StubMarketIndicatorsProvider(indicators: MarketIndicatorsFixture.indicators())
        let clock = TestClock()
        let viewModel = makeViewModel(provider: provider, clock: clock)

        viewModel.onViewAppear()
        _ = try await content(of: viewModel)

        clock.advance(by: 14 * 60)
        viewModel.onViewAppear()
        viewModel.feedSheetSizeDidChange(to: .medium)

        #expect(provider.currencies.count == 1)
    }

    @Test("Does not start a second request while the first is still in flight")
    func asksOnceWhileTheRequestIsInFlight() async throws {
        let provider = StubMarketIndicatorsProvider(indicators: MarketIndicatorsFixture.indicators())
        let viewModel = makeViewModel(provider: provider)

        viewModel.onViewAppear()
        viewModel.feedSheetSizeDidChange(to: .medium)
        viewModel.onViewAppear()

        _ = try await content(of: viewModel)

        #expect(provider.currencies.count == 1)
    }

    /// The backend recomputes the indicators every 15 minutes, so a reading that old is asked for again.
    @Test("Asks again for a reading older than the backend's refresh interval")
    func refreshesAStaleReading() async throws {
        let provider = StubMarketIndicatorsProvider(indicators: MarketIndicatorsFixture.indicators())
        let clock = TestClock()
        let viewModel = makeViewModel(provider: provider, clock: clock)

        viewModel.onViewAppear()
        _ = try await content(of: viewModel)

        clock.advance(by: 15 * 60)
        viewModel.onViewAppear()

        #expect(await waitUntilConditionMet { provider.currencies.count == 2 })
        #expect(viewModel.state.content != nil)
    }

    @Test("Keeps the reading on screen when a refresh fails")
    func keepsTheReadingWhenARefreshFails() async throws {
        let provider = StubMarketIndicatorsProvider(results: [
            .success(MarketIndicatorsFixture.indicators()),
            .failure(MarketIndicatorsTestError.network),
        ])
        let clock = TestClock()
        let viewModel = makeViewModel(provider: provider, clock: clock)

        viewModel.onViewAppear()
        let loaded = try await content(of: viewModel)

        clock.advance(by: 15 * 60)
        viewModel.onViewAppear()
        #expect(await waitUntilConditionMet { provider.currencies.count == 2 })

        #expect(viewModel.state.content?.totalMarketCap == loaded.totalMarketCap)
    }

    @Test("Opens the description of whatever was tapped")
    func opensInfoSheets() async throws {
        let router = StubCryptoFeedRoutable()
        let viewModel = makeViewModel(provider: StubMarketIndicatorsProvider(indicators: MarketIndicatorsFixture.indicators()), router: router)
        viewModel.onViewAppear()

        let content = try await content(of: viewModel)
        let firstMetric = try #require(content.metrics.first)

        viewModel.onInfoTap()
        viewModel.onMetricTap(firstMetric)

        #expect(router.subjects.count == 2)
        guard case .totalMarketCap = try #require(router.subjects.first) else {
            Issue.record("The info button must describe the capitalisation itself")
            return
        }

        guard case .index(let metric) = try #require(router.subjects.last) else {
            Issue.record("A card must describe its own reading")
            return
        }

        #expect(metric.kind == .fearGreed)
    }

    // MARK: - Helpers

    private func makeViewModel(
        provider: StubMarketIndicatorsProvider,
        router: StubCryptoFeedRoutable = StubCryptoFeedRoutable(),
        clock: TestClock = TestClock()
    ) -> MarketCapViewModel {
        MarketCapViewModel(router: router, indicatorsProvider: provider, now: { clock.now })
    }

    private func content(of viewModel: MarketCapViewModel) async throws -> MarketCapViewModel.Content {
        _ = await waitUntilConditionMet { !viewModel.state.isLoading }

        return try #require(viewModel.state.content)
    }
}

// MARK: - Metric

@Suite("MarketCapViewModel.Metric", .tags(.marketIndicators))
struct MarketCapMetricTests {
    @Test("Rounds the reading it prints, pinning it to the scale", arguments: [(Decimal, String)]([
        (Decimal(string: "49.6")!, "50"),
        (Decimal(string: "49.4")!, "49"),
        (Decimal(105), "100"),
        (Decimal(-5), "0"),
    ]))
    func roundsReading(value: Decimal, expected: String) throws {
        let metric = try #require(MarketCapViewModel.Metric(kind: .fearGreed, indicator: .init(value: value, classification: "Neutral")))

        #expect(metric.value == expected)
    }

    @Test("Places the reading on the scale", arguments: [(Decimal, CGFloat)]([
        (Decimal(0), 0),
        (Decimal(25), 0.25),
        (Decimal(100), 1),
        (Decimal(105), 1),
        (Decimal(-5), 0),
    ]))
    func placesReadingOnScale(value: Decimal, expected: CGFloat) throws {
        let metric = try #require(MarketCapViewModel.Metric(kind: .altcoinIndex, indicator: .init(value: value, classification: "Bitcoin Season")))

        #expect(metric.progress == expected)
    }

    @Test("Colours the label by the band the reading falls into", arguments: [(Decimal, MarketCapViewModel.Metric.Appearance)]([
        (Decimal(0), .red),
        (Decimal(33), .red),
        (Decimal(string: "33.1")!, .yellow),
        (Decimal(49), .yellow),
        (Decimal(string: "49.1")!, .green),
        (Decimal(66), .green),
        (Decimal(string: "66.1")!, .blue),
        (Decimal(100), .blue),
    ]))
    func coloursLabelByBand(value: Decimal, expected: MarketCapViewModel.Metric.Appearance) throws {
        let metric = try #require(MarketCapViewModel.Metric(kind: .fearGreed, indicator: .init(value: value, classification: "Neutral")))

        #expect(metric.appearance == expected)
    }

    @Test("Has nothing to show without a reading")
    func needsAReading() {
        #expect(MarketCapViewModel.Metric(kind: .fearGreed, indicator: nil) == nil)
    }
}

// MARK: - Private

private extension MarketCapViewModel.State {
    var isLoading: Bool {
        if case .loading = self {
            return true
        }

        return false
    }

    var content: MarketCapViewModel.Content? {
        if case .content(let content) = self {
            return content
        }

        return nil
    }
}

// MARK: - Stubs

private final class TestClock {
    private(set) var now = Date(timeIntervalSince1970: 1_757_000_000)

    func advance(by interval: TimeInterval) {
        now += interval
    }
}

private final class StubMarketIndicatorsProvider: MarketIndicatorsProvider {
    private(set) var currencies: [String] = []
    private var results: [Result<MarketIndicators, Error>]

    init(results: [Result<MarketIndicators, Error>]) {
        self.results = results
    }

    init(indicators: MarketIndicators) {
        results = [.success(indicators)]
    }

    func indicators(currency: String) async throws -> MarketIndicators {
        currencies.append(currency)

        return try (results.count > 1 ? results.removeFirst() : results[0]).get()
    }
}

private final class StubCryptoFeedRoutable: CryptoFeedRoutable {
    var subjects: [MarketCapInfoSubject] = []

    func openToken(_ token: MarketsTokenModel) {}
    func openPulseTagFilter(with input: PulseTagFilterInput) {}
    func openMarketCapInfo(subject: MarketCapInfoSubject) { subjects.append(subject) }
}
