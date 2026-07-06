//
//  MarketingBannerNotificationInputFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum MarketingBannerNotificationInputFactory {
    static func makeInput(
        for banner: MarketingBanner,
        incomingActionHandler: IncomingActionHandler,
        dismiss: @escaping NotificationView.NotificationAction
    ) -> NotificationViewInput {
        let event = MarketingBannerNotificationEvent(banner: banner)

        let style: NotificationView.Style = switch banner.action {
        case .deeplink(let url):
            .tappable(hasChevron: true) { _ in
                _ = incomingActionHandler.handleIncomingURL(url)
            }
        case .none:
            .plain
        }

        return NotificationViewInput(
            style: style,
            severity: event.severity,
            settings: .init(event: event, dismissAction: banner.isDismissible ? dismiss : nil)
        )
    }
}
