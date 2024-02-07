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

    private var activePromotions: Set<BannerPromotion> = []

    init() {}
}

// MARK: - PromotionService

extension CommonBannerPromotionService: BannerPromotionService {
    func updatePromotions() async {
        do {
            let promotion = BannerPromotion.changelly
            let promotionInfo = try await tangemApiService.expressPromotion(request: .init(programName: promotion.rawValue))
            let now = Date()
            if promotionInfo.all.timeline.start < now, now < promotionInfo.all.timeline.end {
                activePromotions.insert(promotion)
            }
        } catch {
            AppLog.shared.debug("Check promotions catch error")
            AppLog.shared.error(error)
        }
    }

    func isActive(promotion: BannerPromotion, on place: BannerPromotionPlace) -> Bool {
        let shouldVisible = !isHidden(promotion: promotion, on: place)
        return shouldVisible && activePromotions.contains(promotion)
    }

    func isHidden(promotion: BannerPromotion, on place: BannerPromotionPlace) -> Bool {
        switch place {
        case .main:
            return AppSettings.shared.mainPromotionDismissed.contains(promotion.rawValue)
        case .tokenDetails:
            return AppSettings.shared.tokenPromotionDismissed.contains(promotion.rawValue)
        }
    }

    func hide(promotion: BannerPromotion, on place: BannerPromotionPlace) {
        switch place {
        case .main:
//            return AppSettings.shared.mainPromotionDismissed.insert(promotion.rawValue)
            break
        case .tokenDetails:
//            return AppSettings.shared.tokenPromotionDismissed.insert(promotion.rawValue)
            break
        }
    }
}
