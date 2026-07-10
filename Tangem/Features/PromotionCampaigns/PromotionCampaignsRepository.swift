//
//  PromotionCampaignsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct CampaignBannerData {
    let eligibleTokens: [BannerPromotion.Response.Token]
    let startDate: Date
    let endDate: Date
    let campaignStatus: BannerPromotion.Response.Status
    let link: String?
}

/// Singleton — owns the heterogeneous `/promotion` list (`loadPromotionCampaigns`), which returns every active
/// campaign keyed by `name`. Fetched once per wallet and sliced per campaign, so all consumers share one request.
actor PromotionCampaignsRepository {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private var campaignsCache: [String: [BannerPromotion.Response.Promotion]] = [:]
    private var campaignsInflight: [String: Task<[BannerPromotion.Response.Promotion]?, Never>] = [:]

    nonisolated func prewarm(userWalletId: String) {
        Task { _ = await campaigns(userWalletId: userWalletId) }
    }

    func campaignBannerData(userWalletId: String, campaignName: String) async -> CampaignBannerData? {
        let promotions = await campaigns(userWalletId: userWalletId)
        guard let promotion = promotions.first(where: { $0.name == campaignName }) else {
            return nil
        }

        return CampaignBannerData(
            eligibleTokens: promotion.all.tokens,
            startDate: promotion.all.timeline.start,
            endDate: promotion.all.timeline.end,
            campaignStatus: promotion.all.status,
            link: promotion.all.link
        )
    }

    private func campaigns(userWalletId: String) async -> [BannerPromotion.Response.Promotion] {
        if let cached = campaignsCache[userWalletId] {
            return cached
        }

        if let task = campaignsInflight[userWalletId] {
            return await task.value ?? []
        }

        let task = Task<[BannerPromotion.Response.Promotion]?, Never> {
            try? await tangemApiService.loadPromotionCampaigns(userWalletId: userWalletId)
        }

        campaignsInflight[userWalletId] = task

        let campaigns = await task.value
        campaignsInflight[userWalletId] = nil

        if let campaigns {
            campaignsCache[userWalletId] = campaigns
        }

        return campaigns ?? []
    }
}

// MARK: - DI

private struct PromotionCampaignsRepositoryKey: InjectionKey {
    static var currentValue = PromotionCampaignsRepository()
}

extension InjectedValues {
    var promotionCampaignsRepository: PromotionCampaignsRepository {
        get { Self[PromotionCampaignsRepositoryKey.self] }
        set { Self[PromotionCampaignsRepositoryKey.self] = newValue }
    }
}
