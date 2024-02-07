//
//  BannerPromotionService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol BannerPromotionService {
    func updatePromotions() async
    func isActive(promotion: BannerPromotion, on place: BannerPromotionPlace) -> Bool
    func isHidden(promotion: BannerPromotion, on place: BannerPromotionPlace) -> Bool
    func hide(promotion: BannerPromotion, on place: BannerPromotionPlace)
}

enum BannerPromotionPlace: String, Hashable {
    case main
    case tokenDetails
}

private struct BannerPromotionServiceKey: InjectionKey {
    static var currentValue: BannerPromotionService = CommonBannerPromotionService()
}

extension InjectedValues {
    var bannerPromotionService: BannerPromotionService {
        get { Self[BannerPromotionServiceKey.self] }
        set { Self[BannerPromotionServiceKey.self] = newValue }
    }
}
