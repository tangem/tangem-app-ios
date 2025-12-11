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

    init() {}
}

// MARK: - PromotionService

extension CommonBannerPromotionService: BannerPromotionService {
    func activePromotion(promotion: PromotionProgramName, on place: BannerPromotionPlacement) async -> ActivePromotionInfo? {
        guard !isHidden(promotion: promotion, on: place) else {
            return nil
        }

        do {
            let promotionInfo = try await tangemApiService.expressPromotion(request: .init(programName: promotion.rawValue))

            let now = Date()
            if promotionInfo.all.status == .active, now < promotionInfo.all.timeline.end {
                let link: URL? = switch promotion {
                case .visaWaitlist: Constants.visaWaitlinkLink
                case .blackFriday: Constants.blackFridayLink
                case .onePlusOne: Constants.onePlusOneLink
                }

                return .init(bannerPromotion: promotion, timeline: promotionInfo.all.timeline, link: link)
            }

        } catch {
            AppLogger.error("Check promotions catch error", error: error)
        }

        return nil
    }

    func isHidden(promotion: PromotionProgramName, on place: BannerPromotionPlacement) -> Bool {
        switch place {
        case .main:
            return AppSettings.shared.mainPromotionDismissed.contains(promotion.rawValue)
        case .tokenDetails:
            return AppSettings.shared.tokenPromotionDismissed.contains(promotion.rawValue)
        }
    }

    func hide(promotion: PromotionProgramName, on place: BannerPromotionPlacement) {
        switch place {
        case .main:
            AppSettings.shared.mainPromotionDismissed.insert(promotion.rawValue)
        case .tokenDetails:
            AppSettings.shared.tokenPromotionDismissed.insert(promotion.rawValue)
        }
    }
}

private extension CommonBannerPromotionService {
    enum Constants {
        static let visaWaitlinkLink = URL(
            string: "https://tangem.com/en/cardwaitlist/?utm_source=tangem-app-banner&utm_medium=banner&utm_campaign=tangempaywaitlist"
        )!

        static let blackFridayLink = URL(
            string: "https://tangem.com/en/pricing/?promocode=BF2025&utm_source=tangem-app-banner&utm_medium=banner&utm_campaign=BlackFriday2025"
        )!

        static let onePlusOneLink = URL(
            string: "https://tangem.com/pricing/?cat=family&utm_source=tangem-app-banner&utm_medium=banner&utm_campaign=BOGO50"
        )!
    }
}
