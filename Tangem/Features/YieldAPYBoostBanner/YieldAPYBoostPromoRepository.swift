//
//  YieldAPYBoostPromoRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct YieldAPYBoostCampaign {
    let eligibleTokens: [BannerPromotion.Response.Token]
    let startDate: Date
    let endDate: Date
    let campaignStatus: BannerPromotion.Response.Status
    let promoEnrollmentStatus: YieldBoostPromotionDTO.PromoEnrollmentStatus
    let contractAddress: String?
    let networkId: String?
}

private typealias Cache = [UserWalletId: YieldAPYBoostCampaign?]

/// Singleton — token details screens read the cache to gate the per-token promo / active campaign UI.
actor YieldAPYBoostPromoRepository {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private var campaignsCache: Cache = [:]
    private var inflight: [UserWalletId: Task<YieldAPYBoostCampaign?, Never>] = [:]

    func campaign(userWalletId: UserWalletId) async -> YieldAPYBoostCampaign? {
        if let cached = campaignsCache[userWalletId] {
            return cached
        }

        if let task = inflight[userWalletId] {
            return await task.value
        }

        let task = Task<YieldAPYBoostCampaign?, Never> {
            let walletIdString = userWalletId.stringValue
            async let promotionsTask = tangemApiService.loadPromotionCampaigns(userWalletId: walletIdString)
            async let statusTask = tangemApiService.loadYieldBoostPromotionStatus(userWalletId: walletIdString)

            do {
                let (promotions, status) = try await (promotionsTask, statusTask)
                guard let promotion = promotions.first(where: { $0.name == Self.campaignName }) else {
                    return nil
                }

                return YieldAPYBoostCampaign(
                    eligibleTokens: promotion.all.tokens,
                    startDate: promotion.all.timeline.start,
                    endDate: promotion.all.timeline.end,
                    campaignStatus: promotion.all.status,
                    promoEnrollmentStatus: status.promoEnrollmentStatus,
                    contractAddress: status.contractAddress,
                    networkId: status.networkId
                )
            } catch {
                return nil
            }
        }

        inflight[userWalletId] = task

        let campaign = await task.value
        inflight[userWalletId] = nil
        campaignsCache[userWalletId] = campaign
        return campaign
    }
}

extension YieldAPYBoostPromoRepository {
    static let campaignName = "yield-apr-boost"
}

// MARK: - DI

private struct YieldAPYBoostPromoRepositoryKey: InjectionKey {
    static var currentValue = YieldAPYBoostPromoRepository()
}

extension InjectedValues {
    var yieldAPYBoostPromoRepository: YieldAPYBoostPromoRepository {
        get { Self[YieldAPYBoostPromoRepositoryKey.self] }
        set { Self[YieldAPYBoostPromoRepositoryKey.self] = newValue }
    }
}
