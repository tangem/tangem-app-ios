//
//  BannerPromotion.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

enum BannerPromotion: String, Hashable {
    case changelly
}

struct BannerPromotionNotificationFactory {
    @Injected(\.bannerPromotionService) private var bannerPromotionService: BannerPromotionService

    func buildNotificationInput(
        for bannerPromotion: BannerPromotion,
        buttonAction: @escaping NotificationView.NotificationButtonTapAction,
        dismissAction: @escaping NotificationView.NotificationAction
    ) -> NotificationViewInput {
        let event = event(for: bannerPromotion)
        return NotificationViewInput(
            style: .plain,
            severity: .info,
            settings: .init(event: event, dismissAction: dismissAction)
        )
    }

    private func event(for banner: BannerPromotion) -> BannerNotificationEvent {
        switch banner {
        case .changelly:
            return .changelly(title: changellyTitle(), description: changellyDescription())
        }
    }

    private func changellyTitle() -> NotificationView.Title {
        let percent = changellyZeroPercent()
        let attributed = NSMutableAttributedString(
            string: Localization.mainSwapChangellyPromotionTitle(percent),
            attributes: [.font: UIFonts.Bold.footnote, .foregroundColor: UIColor(Colors.Text.constantWhite)]
        )

        if let range = attributed.string.range(of: percent) {
            let yellow = UIColor.yellow // (red: 233, green: 253, blue: 2, alpha: 1)

            attributed.addAttribute(
                .foregroundColor,
                value: yellow,
                range: NSRange(range.lowerBound..., in: attributed.string)
            )
        }

        return .attributed(attributed)
    }

    func changellyDescription() -> String? {
        guard let promotion = bannerPromotionService.activePromotions.first(where: { $0.bannerPromotion == .changelly }) else {
            return nil
        }

        let percent = changellyZeroPercent()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"

        return Localization.mainSwapChangellyPromotionMessage(
            percent,
            formatter.string(from: promotion.timeline.start),
            formatter.string(from: promotion.timeline.end)
        )
    }

    func changellyZeroPercent() -> String {
        PercentFormatter().expressRatePercentFormat(
            value: 0,
            maximumFractionDigits: 0,
            minimumFractionDigits: 0
        )
    }
}

enum BannerNotificationEvent: Hashable, NotificationEvent {
    case changelly(title: NotificationView.Title, description: String?)

    var title: NotificationView.Title {
        switch self {
        case .changelly(let title, let description):
            return title
        }
    }

    var description: String? {
        switch self {
        case .changelly(_, let description):
            return description
        }
    }

    var colorScheme: NotificationView.ColorScheme { .tangemExpressPromotion }
    var icon: NotificationView.MessageIcon {
        .init(
            iconType: .image(Assets.swapBannerIcon.image),
            size: CGSize(bothDimensions: 34)
        )
    }

    var severity: NotificationView.Severity { .info }
    var isDismissable: Bool { true }
    var analyticsEvent: Analytics.Event? { nil }
    var analyticsParams: [Analytics.ParameterKey: String] { [:] }
    var isOneShotAnalyticsEvent: Bool { true }
}
