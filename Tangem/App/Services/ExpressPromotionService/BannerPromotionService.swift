//
//  BannerPromotionService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol BannerPromotionService {
    func activePromotion(place: BannerPromotionPlace) async -> ActivePromotionInfo?

    func isHidden(promotion: PromotionProgramName, on place: BannerPromotionPlace) -> Bool
    func hide(promotion: PromotionProgramName, on place: BannerPromotionPlace)
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

struct ActivePromotionInfo: Hashable {
    let bannerPromotion: PromotionProgramName
    let timeline: Timeline
}

enum BannerPromotionPlace: String, Hashable {
    case main
    case tokenDetails
}

enum PromotionProgramName: String, Hashable {
    case changelly
}
