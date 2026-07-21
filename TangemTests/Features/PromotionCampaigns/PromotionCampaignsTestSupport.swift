//
//  PromotionCampaignsTestSupport.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Testing
@testable import Tangem

/// Use this tag for all promotion-campaigns suites: @Suite(.tags(.promotionCampaigns))
extension Tag {
    @Tag static var promotionCampaigns: Self
}

/// Records wallet ids requested from the promotions list and answers with canned promotions.
final class PromotionCampaignsApiSpy {
    let fake = FakeTangemApiService()

    private let state = OSAllocatedUnfairLock(initialState: [String]())

    init(promotions: [BannerPromotion.Response.Promotion]) {
        fake.loadPromotionCampaignsHandler = { [state] userWalletId in
            state.withLock { $0.append(userWalletId) }
            return promotions
        }
    }

    var requestedWalletIds: [String] {
        state.withLock { $0 }
    }
}

enum PromotionCampaignsFixtures {
    static let yieldCampaignName = YieldAPYBoostPromoRepository.campaignName

    static func makePromotion(
        name: String = yieldCampaignName,
        start: Date = Date(timeIntervalSince1970: 1_782_864_000),
        end: Date = Date(timeIntervalSince1970: 1_785_542_400),
        tokens: [BannerPromotion.Response.Token] = [makeToken()],
        status: BannerPromotion.Response.Status = .active,
        link: String? = "https://tangem.com/promo"
    ) -> BannerPromotion.Response.Promotion {
        BannerPromotion.Response.Promotion(
            name: name,
            all: BannerPromotion.Response.Info(
                timeline: BannerPromotion.Timeline(start: start, end: end),
                tokens: tokens,
                status: status,
                link: link
            )
        )
    }

    static func makeToken(
        tokenId: String = "usd-coin",
        tokenAddress: String = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
        tokenSymbol: String = "USDC",
        tokenName: String = "USD Coin",
        networkId: String = "ethereum",
        decimals: Int = 6
    ) -> BannerPromotion.Response.Token {
        BannerPromotion.Response.Token(
            tokenId: tokenId,
            tokenAddress: tokenAddress,
            tokenSymbol: tokenSymbol,
            tokenName: tokenName,
            networkId: networkId,
            decimals: decimals
        )
    }

    static func makeEnrollmentStatusResponse(
        promoEnrollmentStatus: YieldBoostPromotionDTO.PromoEnrollmentStatus = .notStarted,
        networkId: String? = nil,
        contractAddress: String? = nil,
        qualificationEndDate: Date? = nil
    ) -> YieldBoostPromotionDTO.Response {
        YieldBoostPromotionDTO.Response(
            promoEnrollmentStatus: promoEnrollmentStatus,
            tokenName: nil,
            networkId: networkId,
            moduleAddress: nil,
            userAddress: nil,
            contractAddress: contractAddress,
            activationDate: nil,
            qualificationEndDate: qualificationEndDate,
            disqualificationReason: nil
        )
    }
}
