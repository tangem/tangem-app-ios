//
//  CashbackPromoServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Testing
@testable import Tangem

@Suite("CashbackPromoService", .tags(.campaigns), .serialized)
struct CashbackPromoServiceTests {
    private typealias Fixtures = PromotionCampaignsFixtures

    private var anyCampaignId: String { "whale-swap-cashback" }

    @Test("Campaign is nil without a selected wallet and the backend is not queried")
    func campaignNilWithoutSelectedWallet() async {
        let spy = PromotionCampaignsApiSpy(promotions: [Fixtures.makePromotion(name: anyCampaignId)])

        await withInjectedCampaignDependencies(spy.fake) {
            let campaign = await CashbackPromoService().campaign(id: anyCampaignId)

            #expect(campaign == nil)
            #expect(spy.requestedWalletIds.isEmpty)
        }
    }

    @Test("Campaign is fetched for the selected wallet id")
    func campaignFetchedForSelectedWalletId() async throws {
        let selectedWallet = CampaignUserWalletModelStub(walletIdSeed: "wallet-1")
        let userWalletRepository = FakeUserWalletRepository(models: [selectedWallet])
        userWalletRepository.selectedModel = selectedWallet

        let spy = PromotionCampaignsApiSpy(promotions: [
            Fixtures.makePromotion(name: anyCampaignId, link: "https://tangem.com/cashback"),
        ])

        try await withInjectedCampaignDependencies(spy.fake, userWalletRepository: userWalletRepository) {
            let campaign = try #require(await CashbackPromoService().campaign(id: anyCampaignId))

            #expect(campaign.link == "https://tangem.com/cashback")
            #expect(spy.requestedWalletIds == [selectedWallet.userWalletId.stringValue])
        }
    }

    @Test("Registration sends every field of the enrollment request")
    func registrationSendsEveryRequestField() async throws {
        let apiService = FakeTangemApiService()
        let recordedRequests = OSAllocatedUnfairLock(initialState: [PromotionRegistrationDTO.Request]())
        apiService.registerForPromotionCampaignHandler = { request in
            recordedRequests.withLock { $0.append(request) }
            return PromotionRegistrationDTO.Response(status: .saved)
        }

        let registration = CashbackRegistration(
            campaignId: anyCampaignId,
            walletIds: ["wallet-1", "wallet-2"],
            tokenReward: .init(
                networkId: "ethereum",
                userAddress: "0xUser",
                tokenAddress: "0xToken",
                tokenId: "usd-coin"
            )
        )

        try await withInjectedCampaignDependencies(apiService) {
            _ = try await CashbackPromoService().register(registration)

            let request = try #require(recordedRequests.withLock { $0.first })
            #expect(request.campaignId == "whale-swap-cashback")
            #expect(request.walletIds == ["wallet-1", "wallet-2"])
            #expect(request.tokenReward.networkId == "ethereum")
            #expect(request.tokenReward.userAddress == "0xUser")
            #expect(request.tokenReward.tokenAddress == "0xToken")
            #expect(request.tokenReward.tokenId == "usd-coin")
        }
    }

    @Test("Registration maps backend statuses to enrollment results", arguments: [
        (PromotionRegistrationDTO.Response.Status.saved, CashbackRegistrationResult.registered),
        (PromotionRegistrationDTO.Response.Status.alreadyExists, CashbackRegistrationResult.alreadyEnrolled),
    ])
    func registrationMapsBackendStatuses(
        backendStatus: PromotionRegistrationDTO.Response.Status,
        expected: CashbackRegistrationResult
    ) async throws {
        let apiService = FakeTangemApiService()
        apiService.registerForPromotionCampaignHandler = { _ in
            PromotionRegistrationDTO.Response(status: backendStatus)
        }

        try await withInjectedCampaignDependencies(apiService) {
            let result = try await CashbackPromoService().register(makeRegistration())

            #expect(result == expected)
        }
    }

    @Test("Registration rethrows the backend error")
    func registrationRethrowsBackendError() async {
        let apiService = FakeTangemApiService()
        apiService.registerForPromotionCampaignHandler = { _ in throw TestError.sample }

        await withInjectedCampaignDependencies(apiService) {
            do {
                _ = try await CashbackPromoService().register(makeRegistration())
                Issue.record("Expected registration to rethrow")
            } catch TestError.sample {
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }
    }

    private func makeRegistration() -> CashbackRegistration {
        CashbackRegistration(
            campaignId: anyCampaignId,
            walletIds: ["wallet-1"],
            tokenReward: .init(
                networkId: "ethereum",
                userAddress: "0xUser",
                tokenAddress: "0xToken",
                tokenId: nil
            )
        )
    }
}

private enum TestError: Error {
    case sample
}
