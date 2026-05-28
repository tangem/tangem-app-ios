//
//  TokenPromotionNotificationsManagerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import Testing
@testable import Tangem

@Suite("TokenPromotionNotificationsManager")
struct TokenPromotionNotificationsManagerTests {
    private let walletId = UserWalletId(value: Data([0x01, 0x02, 0x03, 0x04]))

    // MARK: - loadNotifications

    @Test("Returns notifications when token matches")
    func returnsNotificationsWhenTokenMatches() async {
        let promo = makePromotion(id: 1, networkId: "ethereum", tokenAddress: "0xABC")
        let sut = makeSUT(promotions: [promo], networkId: "ethereum", tokenAddress: "0xABC")

        let inputs = await sut.loadNotifications()

        #expect(inputs.count == 1)
    }

    @Test("Returns empty when token does not match")
    func returnsEmptyWhenTokenDoesNotMatch() async {
        let promo = makePromotion(id: 1, networkId: "ethereum", tokenAddress: "0xABC")
        let sut = makeSUT(promotions: [promo], networkId: "polygon", tokenAddress: "0xDEF")

        let inputs = await sut.loadNotifications()

        #expect(inputs.isEmpty)
    }

    @Test("Filters only matching tokens from multiple promotions")
    func filtersOnlyMatchingTokens() async {
        let matching = makePromotion(id: 1, networkId: "ethereum", tokenAddress: "0xABC")
        let nonMatching = makePromotion(id: 2, networkId: "polygon", tokenAddress: "0xDEF")
        let sut = makeSUT(promotions: [matching, nonMatching], networkId: "ethereum", tokenAddress: "0xABC")

        let inputs = await sut.loadNotifications()

        #expect(inputs.count == 1)
    }

    // MARK: - refresh

    @Test("Refresh calls repository with correct placement")
    func refreshCallsRepositoryWithPlacement() async {
        let spy = PromotionRepositorySpy()
        let sut = makeSUT(repository: spy, placement: .tokenDetails, networkId: "eth", tokenAddress: "0x1")

        await sut.refresh()

        #expect(spy.loadPlacementCalls.count == 1)
        #expect(spy.loadPlacementCalls.first?.placement == .tokenDetails)
    }

    @Test("Refresh uses yield placement when configured")
    func refreshUsesYieldPlacement() async {
        let spy = PromotionRepositorySpy()
        let sut = makeSUT(repository: spy, placement: .yield, networkId: "eth", tokenAddress: "0x1")

        await sut.refresh()

        #expect(spy.loadPlacementCalls.first?.placement == .yield)
    }

    // MARK: - hidePromotion

    @Test("Hide promotion calls repository")
    func hidePromotionCallsRepository() async {
        let spy = PromotionRepositorySpy()
        let sut = makeSUT(repository: spy, networkId: "eth", tokenAddress: "0x1")

        await sut.hidePromotion(displayId: 123)

        #expect(spy.hidePromotionCalls.count == 1)
        #expect(spy.hidePromotionCalls.first?.displayId == 123)
    }
}

// MARK: - Helpers

private extension TokenPromotionNotificationsManagerTests {
    func makeSUT(
        promotions: [Promotion] = [],
        placement: PromotionPlacement = .tokenDetails,
        networkId: String,
        tokenAddress: String
    ) -> TokenPromotionNotificationsManager {
        let repository = PromotionRepositoryStub(promotions: promotions)
        return makeSUT(repository: repository, placement: placement, networkId: networkId, tokenAddress: tokenAddress)
    }

    func makeSUT(
        repository: PromotionRepository,
        placement: PromotionPlacement = .tokenDetails,
        networkId: String,
        tokenAddress: String
    ) -> TokenPromotionNotificationsManager {
        TokenPromotionNotificationsManager(
            userWalletId: walletId,
            placement: placement,
            networkId: networkId,
            tokenAddress: tokenAddress,
            repository: repository
        )
    }

    func makePromotion(id: Int, networkId: String, tokenAddress: String) -> Promotion {
        Promotion(
            id: id,
            placeholder: .tokenDetails,
            priority: "high",
            title: "Test",
            subtitle: "Subtitle",
            iconUrl: nil,
            deeplink: nil,
            buttonEnabled: false,
            buttonText: nil,
            dismissable: true,
            tokens: [
                Promotion.TokenInfo(
                    networkId: networkId,
                    token: Promotion.Token(id: "t", symbol: "T", name: "Token", address: tokenAddress, decimalCount: 18)
                ),
            ]
        )
    }
}

// MARK: - Test Doubles

private final class PromotionRepositoryStub: PromotionRepository {
    private let promotions: [Promotion]

    init(promotions: [Promotion]) {
        self.promotions = promotions
    }

    func promotionsPublisher(userWalletId: UserWalletId, placeholder: PromotionPlacement) -> AnyPublisher<[Promotion], Never> {
        Just(promotions).eraseToAnyPublisher()
    }

    func loadPromotions(userWalletId: UserWalletId) async {}
    func loadPromotions(userWalletId: UserWalletId, placeholder: PromotionPlacement) async {}
    func hidePromotion(userWalletId: UserWalletId, displayId: Int) async {}
}

private final class PromotionRepositorySpy: PromotionRepository {
    struct LoadPlacementCall { let walletId: UserWalletId; let placement: PromotionPlacement }
    struct HideCall { let walletId: UserWalletId; let displayId: Int }

    private(set) var loadPlacementCalls: [LoadPlacementCall] = []
    private(set) var hidePromotionCalls: [HideCall] = []

    func promotionsPublisher(userWalletId: UserWalletId, placeholder: PromotionPlacement) -> AnyPublisher<[Promotion], Never> {
        Just([]).eraseToAnyPublisher()
    }

    func loadPromotions(userWalletId: UserWalletId) async {}

    func loadPromotions(userWalletId: UserWalletId, placeholder: PromotionPlacement) async {
        loadPlacementCalls.append(LoadPlacementCall(walletId: userWalletId, placement: placeholder))
    }

    func hidePromotion(userWalletId: UserWalletId, displayId: Int) async {
        hidePromotionCalls.append(HideCall(walletId: userWalletId, displayId: displayId))
    }
}
