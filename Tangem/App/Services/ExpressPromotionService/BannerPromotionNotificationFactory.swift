//
//  BannerPromotionNotificationFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

struct BannerPromotionNotificationFactory {
    func buildMainBannerNotificationInput(
        promotion: ActivePromotionInfo,
        dismissAction: @escaping NotificationView.NotificationAction
    ) -> NotificationViewInput {
        let event = event(for: promotion, place: .main)
        return NotificationViewInput(
            style: .plain,
            severity: .info,
            settings: .init(event: event, dismissAction: dismissAction)
        )
    }

    func buildTokenBannerNotificationInput(
        promotion: ActivePromotionInfo,
        buttonAction: @escaping NotificationView.NotificationButtonTapAction,
        dismissAction: @escaping NotificationView.NotificationAction
    ) -> NotificationViewInput {
        let event = event(for: promotion, place: .tokenDetails)
        return NotificationViewInput(
            style: .withButtons([.init(action: buttonAction, actionType: .exchange, isWithLoader: false)]),
            severity: .info,
            settings: .init(event: event, dismissAction: dismissAction)
        )
    }

    private func event(for promotion: ActivePromotionInfo, place: BannerPromotionPlace) -> BannerNotificationEvent {
        switch promotion.bannerPromotion {
        case .changelly:
            return .changelly(
                title: changellyTitle(place: place),
                description: changellyDescription(promotion: promotion, place: place)
            )
        }
    }

    private func changellyTitle(place: BannerPromotionPlace) -> NotificationView.Title {
        let percent = changellyZeroPercent()
        let string: String = {
            switch place {
            case .main:
                return Localization.mainSwapChangellyPromotionTitle(percent)
            case .tokenDetails:
                return Localization.tokenSwapChangellyPromotionTitle(percent)
            }
        }()

        let attributed = NSMutableAttributedString(
            string: string,
            attributes: [.font: UIFonts.Bold.footnote, .foregroundColor: UIColor(Colors.Text.constantWhite)]
        )

        if let range = attributed.string.range(of: percent) {
            attributed.addAttribute(
                .foregroundColor,
                value: UIColor(red: 233, green: 253, blue: 2, alpha: 1),
                range: NSRange(range.lowerBound..., in: attributed.string)
            )
        }

        return .attributed(attributed)
    }

    func changellyDescription(promotion: ActivePromotionInfo, place: BannerPromotionPlace) -> String? {
        let percent = changellyZeroPercent()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"

        switch place {
        case .main:
            return Localization.mainSwapChangellyPromotionMessage(
                percent,
                formatter.string(from: promotion.timeline.start),
                formatter.string(from: promotion.timeline.end)
            )
        case .tokenDetails:
            return Localization.tokenSwapChangellyPromotionMessage(
                percent,
                formatter.string(from: promotion.timeline.start),
                formatter.string(from: promotion.timeline.end)
            )
        }
    }

    func changellyZeroPercent() -> String {
        PercentFormatter().expressRatePercentFormat(
            value: 0,
            maximumFractionDigits: 0,
            minimumFractionDigits: 0
        )
    }
}
