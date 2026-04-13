//
//  FakePromotionNotificationsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class FakePromotionNotificationsManager: PromotionNotificationsManager {
    private let mockInputs: [NotificationViewInput]

    var notificationInputs: [NotificationViewInput] { mockInputs }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        Just(mockInputs).eraseToAnyPublisher()
    }

    init() {
        let factory = NotificationsFactory()

        let promotions: [Promotion] = [
            .init(
                id: 1,
                placeholder: .main,
                priority: "high",
                title: "Buy Bitcoin with 0% fee",
                subtitle: "Limited time offer for Tangem users",
                iconUrl: IconURLBuilder().tokenIconURL(id: "bitcoin"),
                deeplink: URL(string: "tangem://buy?currency=BTC"),
                buttonEnabled: true,
                buttonText: "Buy Now",
                dismissable: true
            ),
            .init(
                id: 2,
                placeholder: .main,
                priority: "medium",
                title: "Stake ETH and earn rewards",
                subtitle: "Up to 5% APY on Ethereum staking",
                iconUrl: IconURLBuilder().tokenIconURL(id: "ethereum"),
                deeplink: URL(string: "tangem://staking?currency=ETH"),
                buttonEnabled: true,
                buttonText: "Stake Now",
                dismissable: true
            ),
        ]

        mockInputs = promotions.map { promotion in
            let event = PromotionNotificationEvent(promotion: promotion, buttonAction: nil)
            return factory.buildNotificationInput(for: event)
        }
    }

    func loadPromotions() async {}

    func setupManager(with delegate: NotificationTapDelegate?) {}

    func dismissNotification(with id: NotificationViewId) {}
}
