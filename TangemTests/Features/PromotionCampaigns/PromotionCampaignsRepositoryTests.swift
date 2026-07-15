//
//  PromotionCampaignsRepositoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemTestKit
import Testing
@testable import Tangem

@Suite("PromotionCampaignsRepository", .tags(.promotionCampaigns), .serialized)
final class PromotionCampaignsRepositoryTests: LeakTrackingTestSuite {
    private typealias Fixtures = PromotionCampaignsFixtures

    private let anyWalletId = "wallet-1"

    private func makeSUT() -> PromotionCampaignsRepository {
        trackForMemoryLeaks(PromotionCampaignsRepository())
    }

    @Test("Returns only the campaign matching the requested name")
    func filtersCampaignsByName() async throws {
        let apiSpy = PromotionCampaignsApiSpy(promotions: [
            Fixtures.makePromotion(name: "cashback-campaign", link: "https://tangem.com/cashback"),
            Fixtures.makePromotion(name: Fixtures.yieldCampaignName, link: "https://tangem.com/yield"),
        ])

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()

            let yieldData = await sut.campaignBannerData(
                userWalletId: anyWalletId,
                campaignName: Fixtures.yieldCampaignName
            )
            let unknownData = await sut.campaignBannerData(
                userWalletId: anyWalletId,
                campaignName: "nonexistent-campaign"
            )

            #expect(yieldData?.link == "https://tangem.com/yield")
            #expect(unknownData == nil)
        }
    }

    @Test("Maps every banner data field from the promotion payload")
    func mapsBannerDataFields() async throws {
        let start = Date(timeIntervalSince1970: 1_782_864_000)
        let end = Date(timeIntervalSince1970: 1_785_542_400)
        let token = Fixtures.makeToken(tokenAddress: "0xToken", networkId: "polygon")
        let apiSpy = PromotionCampaignsApiSpy(promotions: [
            Fixtures.makePromotion(start: start, end: end, tokens: [token], status: .active, link: "https://tangem.com/promo"),
        ])

        try await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()

            let bannerData = try #require(await sut.campaignBannerData(
                userWalletId: anyWalletId,
                campaignName: Fixtures.yieldCampaignName
            ))

            #expect(bannerData.startDate == start)
            #expect(bannerData.endDate == end)
            #expect(bannerData.campaignStatus == .active)
            #expect(bannerData.link == "https://tangem.com/promo")
            #expect(bannerData.eligibleTokens.map(\.tokenAddress) == ["0xToken"])
            #expect(bannerData.eligibleTokens.map(\.networkId) == ["polygon"])
        }
    }

    @Test("Campaign list is fetched once per wallet and cached")
    func cachesCampaignsPerWallet() async throws {
        let apiSpy = PromotionCampaignsApiSpy(promotions: [Fixtures.makePromotion()])

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()

            _ = await sut.campaignBannerData(userWalletId: "wallet-1", campaignName: Fixtures.yieldCampaignName)
            _ = await sut.campaignBannerData(userWalletId: "wallet-1", campaignName: "cashback-campaign")
            #expect(apiSpy.requestedWalletIds == ["wallet-1"])

            _ = await sut.campaignBannerData(userWalletId: "wallet-2", campaignName: Fixtures.yieldCampaignName)
            #expect(apiSpy.requestedWalletIds == ["wallet-1", "wallet-2"])
        }
    }

    @Test("Failed fetch is not cached, so the next request retries and recovers")
    func failureIsNotCached() async throws {
        let attempts = OSAllocatedUnfairLock(initialState: 0)
        let apiService = FakeTangemApiService()
        apiService.loadPromotionCampaignsHandler = { _ in
            let attempt = attempts.withLock { count -> Int in
                count += 1
                return count
            }

            if attempt == 1 {
                throw TestError.sample
            }

            return [Fixtures.makePromotion()]
        }

        await withInjectedTangemApiService(apiService) {
            let sut = makeSUT()

            let firstResult = await sut.campaignBannerData(
                userWalletId: anyWalletId,
                campaignName: Fixtures.yieldCampaignName
            )
            let secondResult = await sut.campaignBannerData(
                userWalletId: anyWalletId,
                campaignName: Fixtures.yieldCampaignName
            )

            #expect(firstResult == nil)
            #expect(secondResult != nil)
            #expect(attempts.withLock { $0 } == 2)
        }
    }

    @Test("Successful empty list is cached and not retried")
    func emptyListIsCached() async throws {
        let apiSpy = PromotionCampaignsApiSpy(promotions: [])

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()

            let firstResult = await sut.campaignBannerData(
                userWalletId: anyWalletId,
                campaignName: Fixtures.yieldCampaignName
            )
            let secondResult = await sut.campaignBannerData(
                userWalletId: anyWalletId,
                campaignName: Fixtures.yieldCampaignName
            )

            #expect(firstResult == nil)
            #expect(secondResult == nil)
            #expect(apiSpy.requestedWalletIds == [anyWalletId])
        }
    }

    @Test("Concurrent requests for the same wallet share one in-flight fetch")
    func concurrentRequestsShareInflightFetch() async throws {
        let gate = AsyncGate()
        let counter = OSAllocatedUnfairLock(initialState: 0)
        let apiService = FakeTangemApiService()
        apiService.loadPromotionCampaignsHandler = { _ in
            counter.withLock { $0 += 1 }
            await gate.wait()
            return [Fixtures.makePromotion()]
        }

        await withInjectedTangemApiService(apiService) {
            let sut = makeSUT()

            async let first = sut.campaignBannerData(
                userWalletId: anyWalletId,
                campaignName: Fixtures.yieldCampaignName
            )

            // Park the first request at the gate before issuing the second one, so the second
            // can only resolve through the shared in-flight task, not through the cache.
            let firstParkedAtGate = await waitUntilConditionMet { counter.withLock { $0 } == 1 }
            #expect(firstParkedAtGate)

            async let second = sut.campaignBannerData(
                userWalletId: anyWalletId,
                campaignName: Fixtures.yieldCampaignName
            )

            await gate.open()

            let (firstResult, secondResult) = await (first, second)
            #expect(firstResult != nil)
            #expect(secondResult != nil)
            #expect(counter.withLock { $0 } == 1)
        }
    }
}

// MARK: - Test doubles

/// Suspends handler execution until the test opens the gate — lets concurrent callers pile up deterministically.
private actor AsyncGate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        if isOpen {
            return
        }

        await withCheckedContinuation { waiters.append($0) }
    }

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }
}

private enum TestError: Error {
    case sample
}
