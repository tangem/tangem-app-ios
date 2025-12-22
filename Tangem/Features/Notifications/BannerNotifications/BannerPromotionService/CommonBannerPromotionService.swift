//
//  CommonBannerPromotionService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

let PromotionLogger = AppLogger.tag("Banner promotion")

class CommonBannerPromotionService {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    init() {}
}

// MARK: - BannerPromotionService

extension CommonBannerPromotionService: BannerPromotionService {
    func loadPromotion(programName: String) async -> PromotionServicePromotionInfo {
        do {
            let request = ExpressPromotion.Request(programName: programName)
            let promotionInfo = try await tangemApiService.expressPromotion(request: request)

            PromotionLogger.info("Promotion - \(programName) is \(promotionInfo.all.status) and timeline is \(promotionInfo.all.timeline)")

            switch promotionInfo.all.status {
            case .active where .now < promotionInfo.all.timeline.end:
                return .active(promotionInfo)
            default:
                return .expired
            }
        } catch {
            PromotionLogger.error("Check promotions catch error", error: error)
            return .loadingError(error)
        }
    }

    func activePromotion(promotion: PromotionProgramName, on place: BannerPromotionPlacement) async -> ActivePromotionInfo? {
        // Promotion is not hidden
        guard !isHidden(promotion: promotion, on: place) else {
            return nil
        }

        switch await loadPromotion(programName: promotion.rawValue) {
        case .active(let promotionInfo):
            let activePromotionInfo = try? mapToActivePromotionInfo(promotionInfo: promotionInfo)
            return activePromotionInfo
        case .expired, .loadingError:
            return nil
        }
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

// MARK: - Private

private extension CommonBannerPromotionService {
    func mapToActivePromotionInfo(promotionInfo: PromotionServicePromotionInfo.PromotionInfo) throws -> ActivePromotionInfo {
        guard let promotion = PromotionProgramName(rawValue: promotionInfo.name) else {
            throw Error.wrongPromotionProgramName
        }

        let link: URL? = switch promotion {
        case .visaWaitlist: Constants.visaWaitlinkLink
        case .blackFriday: Constants.blackFridayLink
        case .onePlusOne: Constants.onePlusOneLink
        }

        return .init(bannerPromotion: promotion, timeline: promotionInfo.all.timeline, link: link)
    }
}

// MARK: - Constants

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

// MARK: - Error

private extension CommonBannerPromotionService {
    enum Error: LocalizedError {
        case wrongPromotionProgramName

        var errorDescription: String? {
            switch self {
            case .wrongPromotionProgramName: "Wrong promotion program name"
            }
        }
    }
}
