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

    private var _activePromotions: Set<PromotionType> = []

    init() {}
}

struct PromotionType: Hashable {
    let bannerPromotion: BannerPromotion
    let timeline: Timeline
}

// MARK: - PromotionService

extension CommonBannerPromotionService: BannerPromotionService {
    var activePromotions: Set<PromotionType> { _activePromotions }

    func updatePromotions() async {
        do {
            let promotion = BannerPromotion.changelly
            let promotionInfo = try await tangemApiService.expressPromotion(request: .init(programName: promotion.rawValue))
            let now = Date()
            if promotionInfo.all.timeline.start < now, now < promotionInfo.all.timeline.end {
                _activePromotions.insert(.init(bannerPromotion: promotion, timeline: promotionInfo.all.timeline))
            }
        } catch {
            AppLog.shared.debug("Check promotions catch error \(error)")
            AppLog.shared.error(error)
        }
    }

    func isActive(promotion: BannerPromotion, on place: BannerPromotionPlace) -> Bool {
        let shouldVisible = !isHidden(promotion: promotion, on: place)
        return shouldVisible && activePromotions.contains(where: { $0.bannerPromotion == promotion })
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
        return

        switch place {
        case .main:
            AppSettings.shared.mainPromotionDismissed.insert(promotion.rawValue)
        case .tokenDetails:
            AppSettings.shared.tokenPromotionDismissed.insert(promotion.rawValue)
        }
    }
}
