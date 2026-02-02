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
    func loadActivePromotionsFor(walletId: String, on place: BannerPromotionPlacement) async -> [ActivePromotionInfo] {
        do {
            let request = ExpressPromotion.NewRequest(walletId: walletId)
            let promotionInfos = try await tangemApiService.expressPromotion(request: request).promotions

            let activePromotions = promotionInfos.filter { promotion in
                PromotionLogger.info(
                    "Promotion - \(promotion.name) is \(promotion.all.status) and timeline is \(promotion.all.timeline)"
                )

                switch promotion.all.status {
                case .active where .now < promotion.all.timeline.end:
                    return !isHidden(promotionName: promotion.name, on: place)
                default:
                    return false
                }
            }

            return activePromotions.compactMap { try? mapToActivePromotionInfo(promotionInfo: $0) }

        } catch {
            return []
        }
    }

    func isHidden(promotionName: String, on place: BannerPromotionPlacement) -> Bool {
        switch place {
        case .main:
            return AppSettings.shared.mainPromotionDismissed.contains(promotionName)
        case .tokenDetails:
            return AppSettings.shared.tokenPromotionDismissed.contains(promotionName)
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
    func mapToActivePromotionInfo(promotionInfo: ExpressPromotion.Response.Promotion) throws -> ActivePromotionInfo {
        guard let promotion = PromotionProgramName(rawValue: promotionInfo.name) else {
            throw Error.wrongPromotionProgramName
        }

        let link: URL? = switch promotion {
        case .yield: Constants.yieldLink
        }

        return .init(bannerPromotion: promotion, timeline: promotionInfo.all.timeline, link: link)
    }
}

// MARK: - Constants

private extension CommonBannerPromotionService {
    enum Constants {
        static let yieldLink = URL(string: "https://tangem.com/docs/yield-mode-toc.html")!
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
