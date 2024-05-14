//
//  BannerPromotionService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol BannerPromotionService {
    func activePromotion(promotion: PromotionProgramName, on place: BannerPromotionPlacement) async -> ActivePromotionInfo?
    func isHidden(promotion: PromotionProgramName, on place: BannerPromotionPlacement) -> Bool
    func hide(promotion: PromotionProgramName, on place: BannerPromotionPlacement)
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
    let link: URL?
}

enum BannerPromotionPlacement: String, Hashable {
    case main
    case tokenDetails
}

enum PromotionProgramName: String, Hashable {
    // The promotion has ended
    // Will be deleted: [REDACTED_INFO]
    case changelly
    // Estimated dates 13/05 - 13/06
    // Will be deleted: [REDACTED_INFO]
    case travala
}
