//
//  MarketingBannerServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemTestKit
import Testing
@testable import Tangem

@Suite("MarketingBannerService amount filter", .tags(.marketingBanners))
struct MarketingBannerServiceAmountFilterTests {
    private typealias Fixtures = MarketingCampaignsFixtures

    @Test("Campaign without bounds passes for any amount, including unknown")
    func noBoundsPassesForAnyAmount() {
        let campaign = Fixtures.makeCampaign(minAmount: nil, maxAmount: nil)

        #expect(MarketingBannerService.satisfiesAmount(campaign, usd: nil))
        #expect(MarketingBannerService.satisfiesAmount(campaign, usd: Decimal(string: "0.01")!))
        #expect(MarketingBannerService.satisfiesAmount(campaign, usd: Decimal(string: "1000000")!))
    }

    @Test("Bounded campaign is hidden when the amount is unknown")
    func boundsWithUnknownAmountFails() {
        #expect(!MarketingBannerService.satisfiesAmount(Fixtures.makeCampaign(minAmount: Decimal(string: "100")!), usd: nil))
        #expect(!MarketingBannerService.satisfiesAmount(Fixtures.makeCampaign(maxAmount: Decimal(string: "500")!), usd: nil))
    }

    @Test("Min bound is inclusive")
    func minBoundIsInclusive() {
        let campaign = Fixtures.makeCampaign(minAmount: Decimal(string: "100")!)

        #expect(!MarketingBannerService.satisfiesAmount(campaign, usd: Decimal(string: "99.99")!))
        #expect(MarketingBannerService.satisfiesAmount(campaign, usd: Decimal(string: "100")!))
        #expect(MarketingBannerService.satisfiesAmount(campaign, usd: Decimal(string: "100.01")!))
    }

    @Test("Max bound is inclusive")
    func maxBoundIsInclusive() {
        let campaign = Fixtures.makeCampaign(maxAmount: Decimal(string: "500")!)

        #expect(MarketingBannerService.satisfiesAmount(campaign, usd: Decimal(string: "499.99")!))
        #expect(MarketingBannerService.satisfiesAmount(campaign, usd: Decimal(string: "500")!))
        #expect(!MarketingBannerService.satisfiesAmount(campaign, usd: Decimal(string: "500.01")!))
    }

    @Test("Both bounds form an inclusive range")
    func bothBoundsFormInclusiveRange() {
        let campaign = Fixtures.makeCampaign(
            minAmount: Decimal(string: "100")!,
            maxAmount: Decimal(string: "500")!
        )

        #expect(!MarketingBannerService.satisfiesAmount(campaign, usd: Decimal(string: "50")!))
        #expect(MarketingBannerService.satisfiesAmount(campaign, usd: Decimal(string: "100")!))
        #expect(MarketingBannerService.satisfiesAmount(campaign, usd: Decimal(string: "300")!))
        #expect(MarketingBannerService.satisfiesAmount(campaign, usd: Decimal(string: "500")!))
        #expect(!MarketingBannerService.satisfiesAmount(campaign, usd: Decimal(string: "501")!))
    }
}

@Suite("MarketingBannerService publisher", .tags(.marketingBanners), .serialized)
final class MarketingBannerServicePublisherTests: LeakTrackingTestSuite {
    private typealias Fixtures = MarketingCampaignsFixtures

    private let sourceTokenItem: TokenItem = .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
    private let destinationTokenItem: TokenItem = .token(
        .init(name: "USDT", symbol: "USDT", contractAddress: "0xUSDT", decimalCount: 6),
        .init(.ethereum(testnet: false), derivationPath: nil)
    )

    private var swapRequest: SwapMarketingBannerRequest {
        SwapMarketingBannerRequest(source: sourceTokenItem, destination: destinationTokenItem)
    }

    private func makeSUT() -> MarketingBannerService {
        trackForMemoryLeaks(MarketingBannerService(language: "en"))
    }

    private func makePipeline(
        _ sut: MarketingBannerService,
        requests: CurrentValueSubject<SwapMarketingBannerRequest?, Never>
    ) -> AnyPublisher<MarketingBanners, Never> {
        sut.bannerPublisher(
            for: requests.eraseToAnyPublisher(),
            amount: Just<MarketingBannerAmount?>(nil).eraseToAnyPublisher()
        )
    }

    @Test("Nil request emits empty banners without hitting the API")
    func nilRequestEmitsEmpty() async throws {
        let apiSpy = MarketingCampaignsApiSpy(campaigns: [Fixtures.makeCampaign()])

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()
            let requests = CurrentValueSubject<SwapMarketingBannerRequest?, Never>(nil)

            let emissions = await awaitEmissions(of: { makePipeline(sut, requests: requests) }) { !$0.isEmpty }

            #expect(emissions?.last?.standalone.isEmpty == true)
            #expect(emissions?.last?.linked.isEmpty == true)
            #expect(apiSpy.callCount == 0)
        }
    }

    @Test("Campaigns returned from the backend are emitted as banners")
    func backendCampaignsEmitBanners() async throws {
        let apiSpy = MarketingCampaignsApiSpy(campaigns: [Fixtures.makeCampaign(id: 42)])

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()
            let requests = CurrentValueSubject<SwapMarketingBannerRequest?, Never>(swapRequest)

            let emissions = await awaitEmissions(of: { makePipeline(sut, requests: requests) }) {
                $0.last?.standalone.map(\.id) == [42]
            }

            #expect(emissions != nil)
        }
    }

    @Test("Empty and failing responses both emit empty banners", arguments: [true, false])
    func emptyOrFailingResponseEmitsEmpty(shouldThrow: Bool) async throws {
        let apiService = FakeTangemApiService()
        apiService.loadMarketingCampaignsHandler = { _ in
            if shouldThrow {
                throw TestError.sample
            }

            return MarketingCampaignsDTO.Response(campaigns: [])
        }

        await withInjectedTangemApiService(apiService) {
            let sut = makeSUT()
            let requests = CurrentValueSubject<SwapMarketingBannerRequest?, Never>(swapRequest)

            let emissions = await awaitEmissions(of: { makePipeline(sut, requests: requests) }) { !$0.isEmpty }

            #expect(emissions != nil)
            #expect(emissions?.allSatisfy { $0.standalone.isEmpty && $0.linked.isEmpty } == true)
        }
    }

    @Test("Swap request routes to the swap DTO request with token and language parameters")
    func swapRequestRouting() async throws {
        let apiSpy = MarketingCampaignsApiSpy(campaigns: [])

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()
            let requests = CurrentValueSubject<SwapMarketingBannerRequest?, Never>(swapRequest)

            let subscription = makePipeline(sut, requests: requests).sink { _ in }

            let requested = await waitUntilConditionMet { apiSpy.callCount == 1 }
            #expect(requested)

            let expected = MarketingCampaignsDTO.Request.swap(.init(
                fromNetwork: "ethereum",
                fromContractAddress: nil,
                toNetwork: "ethereum",
                toContractAddress: "0xUSDT",
                language: "en"
            ))
            #expect(apiSpy.recordedRequests == [expected])

            subscription.cancel()
        }
    }

    @Test("Onramp request routes to the onramp DTO request with fiat currency")
    func onrampRequestRouting() async throws {
        let apiSpy = MarketingCampaignsApiSpy(campaigns: [])

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()
            let onrampRequest = OnrampMarketingBannerRequest(destination: sourceTokenItem, fiatCurrencyCode: "EUR")
            let requests = CurrentValueSubject<OnrampMarketingBannerRequest?, Never>(onrampRequest)

            let subscription = sut.bannerPublisher(
                for: requests.eraseToAnyPublisher(),
                amount: Just<MarketingBannerAmount?>(nil).eraseToAnyPublisher()
            ).sink { _ in }

            let requested = await waitUntilConditionMet { apiSpy.callCount == 1 }
            #expect(requested)

            let expected = MarketingCampaignsDTO.Request.onramp(.init(
                toNetwork: "ethereum",
                toContractAddress: nil,
                fiatCurrency: "EUR",
                language: "en"
            ))
            #expect(apiSpy.recordedRequests == [expected])

            subscription.cancel()
        }
    }

    @Test("Duplicate requests fetch once, a distinct request fetches again")
    func duplicateRequestsFetchOnce() async throws {
        let apiSpy = MarketingCampaignsApiSpy(campaigns: [Fixtures.makeCampaign(id: 1)])

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()
            let requests = CurrentValueSubject<SwapMarketingBannerRequest?, Never>(swapRequest)

            let subscription = makePipeline(sut, requests: requests).sink { _ in }

            let initialFetched = await waitUntilConditionMet { apiSpy.callCount == 1 }
            #expect(initialFetched)

            requests.send(swapRequest)
            requests.send(SwapMarketingBannerRequest(source: destinationTokenItem, destination: sourceTokenItem))

            let distinctRequestFetched = await waitUntilConditionMet { apiSpy.callCount == 2 }
            #expect(distinctRequestFetched)

            let expectedInitial = MarketingCampaignsDTO.Request.swap(.init(
                fromNetwork: "ethereum",
                fromContractAddress: nil,
                toNetwork: "ethereum",
                toContractAddress: "0xUSDT",
                language: "en"
            ))
            let expectedReversed = MarketingCampaignsDTO.Request.swap(.init(
                fromNetwork: "ethereum",
                fromContractAddress: "0xUSDT",
                toNetwork: "ethereum",
                toContractAddress: nil,
                language: "en"
            ))
            #expect(apiSpy.recordedRequests == [expectedInitial, expectedReversed])

            subscription.cancel()
        }
    }

    @Test("Request reset to nil clears previously emitted banners")
    func requestResetClearsBanners() async throws {
        let apiSpy = MarketingCampaignsApiSpy(campaigns: [Fixtures.makeCampaign(id: 7)])

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()
            let requests = CurrentValueSubject<SwapMarketingBannerRequest?, Never>(swapRequest)

            let shown = await awaitEmissions(of: { makePipeline(sut, requests: requests) }) {
                $0.last?.standalone.map(\.id) == [7]
            }
            #expect(shown != nil)

            requests.send(nil)

            let cleared = await awaitEmissions(of: { makePipeline(sut, requests: requests) }) {
                $0.last?.standalone.isEmpty == true
            }
            #expect(cleared != nil)
        }
    }

    @Test("Bounded campaign is filtered out when no amount is known")
    func boundedCampaignHiddenWithoutAmount() async throws {
        let apiSpy = MarketingCampaignsApiSpy(campaigns: [
            Fixtures.makeCampaign(id: 1, minAmount: Decimal(string: "100")!),
            Fixtures.makeCampaign(id: 2),
        ])

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()
            let requests = CurrentValueSubject<SwapMarketingBannerRequest?, Never>(swapRequest)

            let emissions = await awaitEmissions(of: { makePipeline(sut, requests: requests) }) {
                $0.last?.standalone.isEmpty == false
            }

            #expect(emissions?.last?.standalone.map(\.id) == [2])
        }
    }

    @Test("Fiat amount is converted to USD before it is compared with the campaign bounds", arguments: [
        (Decimal(150), [1]),
        (Decimal(100), [3]),
    ])
    func fiatAmountIsComparedInUsd(eurAmount: Decimal, expectedIds: [Int]) async throws {
        let apiSpy = MarketingCampaignsApiSpy(campaigns: [
            Fixtures.makeCampaign(id: 1, minAmount: 180, uiType: .standaloneCTA, buttonText: "Join"),
            Fixtures.makeCampaign(id: 2, minAmount: 200, uiType: .pseudoProvider, buttonText: "Request"),
            Fixtures.makeCampaign(id: 3, minAmount: 120, maxAmount: 130, uiType: .standaloneCTA, buttonText: "Join"),
        ])
        apiSpy.fake.loadQuotesHandler = Self.quotes(price: 80000, priceUsd: 100_000)

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()
            let requests = CurrentValueSubject<OnrampMarketingBannerRequest?, Never>(onrampRequest)

            let emissions = await awaitEmissions(of: {
                sut.bannerPublisher(
                    for: requests.eraseToAnyPublisher(),
                    amount: Just<MarketingBannerAmount?>(.fiat(value: eurAmount, currencyCode: "EUR")).eraseToAnyPublisher()
                )
            }) {
                $0.last?.callToAction.map(\.id) == expectedIds
            }

            #expect(emissions != nil)
        }
    }

    @Test("Amount changes re-filter the fetched campaigns without fetching them again")
    func amountChangesDoNotRefetchCampaigns() async throws {
        let apiSpy = MarketingCampaignsApiSpy(campaigns: [
            Fixtures.makeCampaign(id: 1, minAmount: 100, uiType: .standaloneCTA, buttonText: "Join"),
        ])

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()
            let requests = CurrentValueSubject<OnrampMarketingBannerRequest?, Never>(onrampRequest)
            let amount = CurrentValueSubject<MarketingBannerAmount?, Never>(.fiat(value: 50, currencyCode: "USD"))

            let recorder = PublisherRecorder(sut.bannerPublisher(
                for: requests.eraseToAnyPublisher(),
                amount: amount.eraseToAnyPublisher()
            ))

            let fetched = await waitUntilConditionMet { apiSpy.callCount == 1 }
            #expect(fetched)

            amount.send(.fiat(value: 150, currencyCode: "USD"))
            amount.send(.fiat(value: 250, currencyCode: "USD"))

            let shown = await waitUntilConditionMet { recorder.values.last?.callToAction.map(\.id) == [1] }
            #expect(shown)

            let refetched = await waitUntilConditionMet(timeout: 0.3) { apiSpy.callCount > 1 }
            #expect(!refetched)
        }
    }

    @Test("Bounded campaign stays hidden when the fiat rate cannot be loaded")
    func boundedCampaignHiddenWithoutFiatRate() async throws {
        let apiSpy = MarketingCampaignsApiSpy(campaigns: [
            Fixtures.makeCampaign(id: 1, minAmount: 100, uiType: .standaloneCTA, buttonText: "Join"),
            Fixtures.makeCampaign(id: 2, uiType: .standaloneCTA, buttonText: "Join"),
        ])
        let quotesRequestCount = OSAllocatedUnfairLock(initialState: 0)
        apiSpy.fake.loadQuotesHandler = { _ in
            quotesRequestCount.withLock { $0 += 1 }
            throw TestError.sample
        }

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()
            let requests = CurrentValueSubject<OnrampMarketingBannerRequest?, Never>(onrampRequest)

            let emissions = await awaitEmissions(of: {
                sut.bannerPublisher(
                    for: requests.eraseToAnyPublisher(),
                    amount: Just<MarketingBannerAmount?>(.fiat(value: 1000, currencyCode: "EUR")).eraseToAnyPublisher()
                )
            }) {
                quotesRequestCount.withLock { $0 } >= 1 && $0.last?.callToAction.map(\.id) == [2]
            }

            #expect(emissions != nil)
        }
    }

    @Test("Campaigns without amount bounds are emitted without loading the fiat rate")
    func unboundedCampaignsSkipFiatRate() async throws {
        let apiSpy = MarketingCampaignsApiSpy(campaigns: [
            Fixtures.makeCampaign(id: 1, uiType: .standaloneCTA, buttonText: "Join"),
        ])
        let quotesRequestCount = OSAllocatedUnfairLock(initialState: 0)
        apiSpy.fake.loadQuotesHandler = { request in
            quotesRequestCount.withLock { $0 += 1 }
            return try Self.quotes(price: 80000, priceUsd: 100_000)(request)
        }

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()
            let requests = CurrentValueSubject<OnrampMarketingBannerRequest?, Never>(onrampRequest)

            let emissions = await awaitEmissions(of: {
                sut.bannerPublisher(
                    for: requests.eraseToAnyPublisher(),
                    amount: Just<MarketingBannerAmount?>(.fiat(value: 1000, currencyCode: "EUR")).eraseToAnyPublisher()
                )
            }) {
                $0.last?.callToAction.map(\.id) == [1]
            }

            #expect(emissions != nil)
            #expect(quotesRequestCount.withLock { $0 } == 0)
        }
    }

    private var onrampRequest: OnrampMarketingBannerRequest {
        OnrampMarketingBannerRequest(destination: sourceTokenItem, fiatCurrencyCode: "EUR")
    }

    private static func quotes(price: Decimal, priceUsd: Decimal) -> (QuotesDTO.Request) throws -> [Quote] {
        { request in
            request.coinIds.map {
                Quote(id: $0, price: price, priceUsd: priceUsd, priceChange: nil, priceChange7d: nil, priceChange30d: nil, prices24h: nil)
            }
        }
    }
}

private enum TestError: Error {
    case sample
}
