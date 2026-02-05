//
//  BannerPromotionService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol BannerPromotionService {
    func loadActivePromotionsFor(walletId: String, on place: BannerPromotionPlacement) async -> [ActivePromotionInfo]
    func isHidden(promotionName: String, on place: BannerPromotionPlacement) -> Bool
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

enum PromotionServicePromotionInfo {
    typealias PromotionInfo = ExpressPromotion.Response

    case expired
    case active(PromotionInfo)
    case loadingError(Error)
}

struct ActivePromotionInfo: Hashable {
    let bannerPromotion: PromotionProgramName
    let timeline: Timeline
    let link: URL?
}

enum BannerPromotionPlacement {
    case main
    case tokenDetails(TokenItem)

    var analyticsValue: Analytics.ParameterValue {
        switch self {
        case .main:
            return .main
        case .tokenDetails:
            return .token
        }
    }
}

enum PromotionProgramName: String, Hashable, CaseIterable {
    case yield = "promo-yield"

    var analyticsEvent: Analytics.Event? {
        Analytics.Event.promotionBannerAppeared
    }

    var analyticsValue: Analytics.ParameterValue {
        switch self {
        case .yield: return Analytics.ParameterValue.yieldPromo
        }
    }
}
