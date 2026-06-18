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
    /// Marketing campaign data from the promotions list (`loadPromotionCampaigns`). `nil` when the
    /// `yield-apr-boost` campaign isn't currently listed — drives the main-screen "join promo" banner.
    let bannerData: BannerData?
    /// Per-wallet enrollment status (`loadYieldBoostPromotionStatus`). Independent of the promotions list.
    let enrollmentStatus: EnrollmentStatus?

    struct BannerData {
        let eligibleTokens: [BannerPromotion.Response.Token]
        let startDate: Date
        let endDate: Date
        let campaignStatus: BannerPromotion.Response.Status
    }

    struct EnrollmentStatus {
        let promoEnrollmentStatus: YieldBoostPromotionDTO.PromoEnrollmentStatus
        let contractAddress: String?
        let networkId: String?
        let qualificationEndDate: Date?
    }
}

/// Singleton — token details screens read the cache to gate the per-token promo / active campaign UI.
actor YieldAPYBoostPromoRepository {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private var campaignsCache: [String: YieldAPYBoostCampaign?] = [:]
    private var campaignInflight: [String: Task<YieldAPYBoostCampaign?, Never>] = [:]

    private var enrollmentStatusCache: [String: YieldAPYBoostCampaign.EnrollmentStatus] = [:]
    private var enrollmentStatusInflight: [String: Task<YieldAPYBoostCampaign.EnrollmentStatus?, Never>] = [:]

    /// Full campaign for the main-screen banner. Fetched once per session.
    func campaign(userWalletId: String) async -> YieldAPYBoostCampaign? {
        if let cached = campaignsCache[userWalletId] {
            return cached
        }

        if let task = campaignInflight[userWalletId] {
            return await task.value
        }

        let task = Task<YieldAPYBoostCampaign?, Never> { [self] in
            async let bannerData = loadBannerData(userWalletId: userWalletId)
            async let enrollmentStatus = enrollmentStatus(userWalletId: userWalletId)

            let (resolvedBannerData, resolvedEnrollmentStatus) = await (bannerData, enrollmentStatus)
            guard resolvedBannerData != nil || resolvedEnrollmentStatus != nil else {
                return nil
            }

            return YieldAPYBoostCampaign(bannerData: resolvedBannerData, enrollmentStatus: resolvedEnrollmentStatus)
        }

        campaignInflight[userWalletId] = task

        let campaign = await task.value
        campaignInflight[userWalletId] = nil
        campaignsCache[userWalletId] = campaign
        return campaign
    }

    /// Per-wallet enrollment status only — does not depend on the promotions list. Successful responses are
    /// cached for the session; failures are NOT cached so a transient error can recover on the next request.
    func enrollmentStatus(userWalletId: String, forceRefresh: Bool = false) async -> YieldAPYBoostCampaign.EnrollmentStatus? {
        guard !FeatureProvider.isAvailable(.redesign) else {
            return nil
        }

        if let task = enrollmentStatusInflight[userWalletId] {
            return await task.value
        }

        if !forceRefresh, let cached = enrollmentStatusCache[userWalletId] {
            return cached
        }

        let task = Task<YieldAPYBoostCampaign.EnrollmentStatus?, Never> {
            do {
                let status = try await tangemApiService.loadYieldBoostPromotionStatus(userWalletId: userWalletId)
                return YieldAPYBoostCampaign.EnrollmentStatus(
                    promoEnrollmentStatus: status.promoEnrollmentStatus,
                    contractAddress: status.contractAddress,
                    networkId: status.networkId,
                    qualificationEndDate: status.qualificationEndDate
                )
            } catch {
                return nil
            }
        }

        enrollmentStatusInflight[userWalletId] = task

        let status = await task.value
        enrollmentStatusInflight[userWalletId] = nil
        if let status {
            enrollmentStatusCache[userWalletId] = status
        }
        return status
    }

    func cachedEnrollmentStatus(userWalletId: String) -> YieldAPYBoostCampaign.EnrollmentStatus? {
        enrollmentStatusCache[userWalletId]
    }

    private func loadBannerData(userWalletId: String) async -> YieldAPYBoostCampaign.BannerData? {
        do {
            let promotions = try await tangemApiService.loadPromotionCampaigns(userWalletId: userWalletId)
            guard let promotion = promotions.first(where: { $0.name == Self.campaignName }) else {
                return nil
            }

            return YieldAPYBoostCampaign.BannerData(
                eligibleTokens: promotion.all.tokens,
                startDate: promotion.all.timeline.start,
                endDate: promotion.all.timeline.end,
                campaignStatus: promotion.all.status
            )
        } catch {
            return nil
        }
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
