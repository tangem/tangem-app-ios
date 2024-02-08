//
//  CommonBannerPromotionService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class CommonBannerPromotionService {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private var activePromotion: ActivePromotionInfo?

    init() {}
}

// MARK: - PromotionService

extension CommonBannerPromotionService: BannerPromotionService {
    func activePromotion(place: BannerPromotionPlace) async -> ActivePromotionInfo? {
        let promotion = PromotionProgramName.changelly
        guard !isHidden(promotion: promotion, on: place) else {
            return nil
        }

        do {
            let promotionInfo = try await tangemApiService.expressPromotion(request: .init(programName: promotion.rawValue))
            let now = Date()
            if promotionInfo.all.status == .active, now < promotionInfo.all.timeline.end {
                activePromotion = .init(bannerPromotion: promotion, timeline: promotionInfo.all.timeline)
            }
        } catch {
            AppLog.shared.debug("Check promotions catch error \(error)")
            AppLog.shared.error(error)
        }

        return activePromotion
    }

    func isHidden(promotion: PromotionProgramName, on place: BannerPromotionPlace) -> Bool {
        switch place {
        case .main:
            return AppSettings.shared.mainPromotionDismissed.contains(promotion.rawValue)
        case .tokenDetails:
            return AppSettings.shared.tokenPromotionDismissed.contains(promotion.rawValue)
        }
    }

    func hide(promotion: PromotionProgramName, on place: BannerPromotionPlace) {
        switch place {
        case .main:
            AppSettings.shared.mainPromotionDismissed.insert(promotion.rawValue)
        case .tokenDetails:
            AppSettings.shared.tokenPromotionDismissed.insert(promotion.rawValue)
        }
    }
}
