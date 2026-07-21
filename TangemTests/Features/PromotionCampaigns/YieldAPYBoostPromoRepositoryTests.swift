//
//  YieldAPYBoostPromoRepositoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemTestKit
import Testing
@testable import Tangem

@Suite("YieldAPYBoostPromoRepository", .tags(.promotionCampaigns), .serialized)
final class YieldAPYBoostPromoRepositoryTests: LeakTrackingTestSuite {
    private typealias Fixtures = PromotionCampaignsFixtures

    private let anyWalletId = "wallet-1"

    private func makeSUT() -> YieldAPYBoostPromoRepository {
        trackForMemoryLeaks(YieldAPYBoostPromoRepository())
    }

    /// Swaps both the API service and the shared promotions repository so every test starts
    /// with an empty campaigns cache.
    private func withInjected(_ apiService: TangemApiService, operation: () async throws -> Void) async rethrows {
        try await InjectedDependenciesIsolation.shared.run {
            let previousApiService = InjectedValues[\.tangemApiService]
            let previousRepository = InjectedValues[\.promotionCampaignsRepository]
            InjectedValues[\.tangemApiService] = apiService
            InjectedValues[\.promotionCampaignsRepository] = PromotionCampaignsRepository()
            defer {
                InjectedValues[\.tangemApiService] = previousApiService
                InjectedValues[\.promotionCampaignsRepository] = previousRepository
            }
            try await operation()
        }
    }

    @Test("Campaign composes banner data from the shared repository with the enrollment status")
    func composesBannerDataAndEnrollmentStatus() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadPromotionCampaignsHandler = { _ in
            [
                Fixtures.makePromotion(name: "cashback-campaign", link: "https://tangem.com/cashback"),
                Fixtures.makePromotion(name: Fixtures.yieldCampaignName, link: "https://tangem.com/yield"),
            ]
        }
        apiService.loadYieldBoostPromotionStatusHandler = { _ in
            Fixtures.makeEnrollmentStatusResponse(
                promoEnrollmentStatus: .notStarted,
                qualificationEndDate: Date(timeIntervalSince1970: 1_785_542_400)
            )
        }

        try await withInjected(apiService) {
            let sut = makeSUT()

            let campaign = try #require(await sut.campaign(userWalletId: anyWalletId))

            let bannerData = try #require(campaign.bannerData)
            #expect(bannerData.link == "https://tangem.com/yield")
            #expect(bannerData.campaignStatus == .active)

            let enrollmentStatus = try #require(campaign.enrollmentStatus)
            #expect(enrollmentStatus.promoEnrollmentStatus == .notStarted)
            #expect(enrollmentStatus.qualificationEndDate == Date(timeIntervalSince1970: 1_785_542_400))
        }
    }

    @Test("Banner data is nil when the promotions list has no yield campaign")
    func bannerDataNilWithoutYieldCampaign() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadPromotionCampaignsHandler = { _ in
            [Fixtures.makePromotion(name: "cashback-campaign")]
        }
        apiService.loadYieldBoostPromotionStatusHandler = { _ in
            Fixtures.makeEnrollmentStatusResponse(promoEnrollmentStatus: .active)
        }

        try await withInjected(apiService) {
            let sut = makeSUT()

            let campaign = try #require(await sut.campaign(userWalletId: anyWalletId))

            #expect(campaign.bannerData == nil)
            #expect(campaign.enrollmentStatus?.promoEnrollmentStatus == .active)
        }
    }

    @Test("Campaign is nil when both the promotions list and the enrollment status are unavailable")
    func campaignNilWhenBothSourcesUnavailable() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadPromotionCampaignsHandler = { _ in throw TestError.sample }
        apiService.loadYieldBoostPromotionStatusHandler = { _ in throw TestError.sample }

        await withInjected(apiService) {
            let sut = makeSUT()

            let campaign = await sut.campaign(userWalletId: anyWalletId)

            #expect(campaign == nil)
        }
    }

    @Test("Enrollment status maps token binding fields")
    func enrollmentStatusMapsFields() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadPromotionCampaignsHandler = { _ in [] }
        apiService.loadYieldBoostPromotionStatusHandler = { _ in
            Fixtures.makeEnrollmentStatusResponse(
                promoEnrollmentStatus: .active,
                networkId: "polygon",
                contractAddress: "0xToken"
            )
        }

        try await withInjected(apiService) {
            let sut = makeSUT()

            let enrollmentStatus = try #require(await sut.enrollmentStatus(userWalletId: anyWalletId))

            #expect(enrollmentStatus.promoEnrollmentStatus == .active)
            #expect(enrollmentStatus.networkId == "polygon")
            #expect(enrollmentStatus.contractAddress == "0xToken")
            #expect(enrollmentStatus.qualificationEndDate == nil)
            #expect(await sut.cachedEnrollmentStatus(userWalletId: anyWalletId)?.promoEnrollmentStatus == .active)
        }
    }
}

private enum TestError: Error {
    case sample
}
