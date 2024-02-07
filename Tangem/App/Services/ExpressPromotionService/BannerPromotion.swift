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

extension BannerPromotion: NotificationEvent {
    var title: NotificationView.Title {
        switch self {
        case .changelly:
            let percent = PercentFormatter().expressRatePercentFormat(value: 0)
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
    }

    var description: String? {
        switch self {
        case .changelly:
            let percent = PercentFormatter().expressRatePercentFormat(value: 0)
            return Localization.mainSwapChangellyPromotionMessage(percent, "11", "22")
        }
    }

    var buttonAction: NotificationButtonActionType? {
        switch self {
        case .changelly:
            return .exchange
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .changelly:
            return .tangemExpressPromotion
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .changelly:
            return .init(iconType: .image(Assets.swapBannerIcon.image), size: CGSize(bothDimensions: 34))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .changelly:
            return .info
        }
    }

    var isDismissable: Bool {
        true
    }

    var analyticsEvent: Analytics.Event? {
        nil
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        [:]
    }

    var isOneShotAnalyticsEvent: Bool {
        true
    }
}
