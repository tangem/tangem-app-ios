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
final class MarketingBannerServiceAmountFilterTests: LeakTrackingTestSuite {
    private typealias Fixtures = MarketingCampaignsFixtures

    private func makeSUT() -> MarketingBannerService {
        trackForMemoryLeaks(MarketingBannerService(language: "en"))
    }

    @Test("Campaign without bounds passes for any amount, including unknown")
    func noBoundsPassesForAnyAmount() {
        let sut = makeSUT()
        let campaign = Fixtures.makeCampaign(minAmount: nil, maxAmount: nil)

        #expect(sut.satisfiesAmount(campaign, usd: nil))
        #expect(sut.satisfiesAmount(campaign, usd: Decimal(string: "0.01")!))
        #expect(sut.satisfiesAmount(campaign, usd: Decimal(string: "1000000")!))
    }

    @Test("Bounded campaign is hidden when the amount is unknown")
    func boundsWithUnknownAmountFails() {
        let sut = makeSUT()

        #expect(!sut.satisfiesAmount(Fixtures.makeCampaign(minAmount: Decimal(string: "100")!), usd: nil))
        #expect(!sut.satisfiesAmount(Fixtures.makeCampaign(maxAmount: Decimal(string: "500")!), usd: nil))
    }

    @Test("Min bound is inclusive")
    func minBoundIsInclusive() {
        let sut = makeSUT()
        let campaign = Fixtures.makeCampaign(minAmount: Decimal(string: "100")!)

        #expect(!sut.satisfiesAmount(campaign, usd: Decimal(string: "99.99")!))
        #expect(sut.satisfiesAmount(campaign, usd: Decimal(string: "100")!))
        #expect(sut.satisfiesAmount(campaign, usd: Decimal(string: "100.01")!))
    }

    @Test("Max bound is inclusive")
    func maxBoundIsInclusive() {
        let sut = makeSUT()
        let campaign = Fixtures.makeCampaign(maxAmount: Decimal(string: "500")!)

        #expect(sut.satisfiesAmount(campaign, usd: Decimal(string: "499.99")!))
        #expect(sut.satisfiesAmount(campaign, usd: Decimal(string: "500")!))
        #expect(!sut.satisfiesAmount(campaign, usd: Decimal(string: "500.01")!))
    }

    @Test("Both bounds form an inclusive range")
    func bothBoundsFormInclusiveRange() {
        let sut = makeSUT()
        let campaign = Fixtures.makeCampaign(
            minAmount: Decimal(string: "100")!,
            maxAmount: Decimal(string: "500")!
        )

        #expect(!sut.satisfiesAmount(campaign, usd: Decimal(string: "50")!))
        #expect(sut.satisfiesAmount(campaign, usd: Decimal(string: "100")!))
        #expect(sut.satisfiesAmount(campaign, usd: Decimal(string: "300")!))
        #expect(sut.satisfiesAmount(campaign, usd: Decimal(string: "500")!))
        #expect(!sut.satisfiesAmount(campaign, usd: Decimal(string: "501")!))
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

            let recorder = PublisherRecorder(makePipeline(sut, requests: requests))

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

            // Let the in-flight emission task settle before the leak check runs.
            _ = await waitUntilConditionMet(timeout: 0.3) { !recorder.values.isEmpty }
        }
    }

    @Test("Onramp request routes to the onramp DTO request with fiat currency")
    func onrampRequestRouting() async throws {
        let apiSpy = MarketingCampaignsApiSpy(campaigns: [])

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()
            let onrampRequest = OnrampMarketingBannerRequest(destination: sourceTokenItem, fiatCurrencyCode: "EUR")
            let requests = CurrentValueSubject<OnrampMarketingBannerRequest?, Never>(onrampRequest)

            let recorder = PublisherRecorder(sut.bannerPublisher(
                for: requests.eraseToAnyPublisher(),
                amount: Just<MarketingBannerAmount?>(nil).eraseToAnyPublisher()
            ))

            let requested = await waitUntilConditionMet { apiSpy.callCount == 1 }
            #expect(requested)

            let expected = MarketingCampaignsDTO.Request.onramp(.init(
                toNetwork: "ethereum",
                toContractAddress: nil,
                fiatCurrency: "EUR",
                language: "en"
            ))
            #expect(apiSpy.recordedRequests == [expected])

            // Let the in-flight emission task settle before the leak check runs.
            _ = await waitUntilConditionMet(timeout: 0.3) { !recorder.values.isEmpty }
        }
    }

    @Test("Duplicate requests fetch once, a distinct request fetches again")
    func duplicateRequestsFetchOnce() async throws {
        let apiSpy = MarketingCampaignsApiSpy(campaigns: [Fixtures.makeCampaign(id: 1)])

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()
            let requests = CurrentValueSubject<SwapMarketingBannerRequest?, Never>(swapRequest)

            let recorder = PublisherRecorder(makePipeline(sut, requests: requests))

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

            // Let the in-flight emission task settle before the leak check runs.
            _ = await waitUntilConditionMet(timeout: 0.3) { recorder.values.count >= 2 }
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
}

private enum TestError: Error {
    case sample
}
