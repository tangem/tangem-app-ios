//
//  BannerPromotionService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol BannerPromotionService {
    func loadPromotion(programName: String) async -> PromotionServicePromotionInfo

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
    case visaWaitlist = "visa-waitlist"
    case blackFriday = "black-friday"
    case onePlusOne = "one-plus-one"

    var analyticsEvent: Analytics.Event? {
        switch self {
        case .blackFriday, .onePlusOne: Analytics.Event.promotionBannerAppeared
        case .visaWaitlist: Analytics.Event.promotionVisaWaitlist
        }
    }

    var analyticsValue: Analytics.ParameterValue {
        switch self {
        case .blackFriday:
            return Analytics.ParameterValue.blackFriday
        case .visaWaitlist:
            return Analytics.ParameterValue.visaWaitlist
        case .onePlusOne:
            return Analytics.ParameterValue.onePlusOne
        }
    }
}
