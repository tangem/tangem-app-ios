//
//  NotificationBannerItemsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemUI

final class NotificationBannerItemsProvider {
    @Published private(set) var items: [NotificationBannerItem] = []

    private let bannerMapper = MultiWalletNotificationBannerMapper()

    init(
        userWalletNotificationManager: NotificationManager,
        tokensNotificationManager: NotificationManager,
        tangemPayNotificationManager: NotificationManager,
        getTangemPayBannerNotificationManager: NotificationManager,
        yieldApyBoostBannerNotificationManager: NotificationManager
    ) {
        let userWalletNotificationInputPublisher: AnyPublisher<[NotificationViewInput], Never> = userWalletNotificationManager
            .notificationPublisher
            .removeDuplicates()
            .eraseToAnyPublisher()

        let tokensNotificationInputPublisher: AnyPublisher<[NotificationViewInput], Never> = tokensNotificationManager
            .notificationPublisher
            .removeDuplicates()
            .eraseToAnyPublisher()

        let tangemPayNotificationInputPublisher: AnyPublisher<[NotificationViewInput], Never> = tangemPayNotificationManager
            .notificationPublisher
            .removeDuplicates()
            .eraseToAnyPublisher()

        let tangemPayBannerNotificationInputPublisher: AnyPublisher<[NotificationViewInput], Never> = getTangemPayBannerNotificationManager
            .notificationPublisher
            .removeDuplicates()
            .eraseToAnyPublisher()

        let yieldApyBoostBannerNotificationInputPublisher: AnyPublisher<[NotificationViewInput], Never> = yieldApyBoostBannerNotificationManager
            .notificationPublisher
            .removeDuplicates()
            .eraseToAnyPublisher()

        let publishers = [
            userWalletNotificationInputPublisher,
            yieldApyBoostBannerNotificationInputPublisher,
            tokensNotificationInputPublisher,
            tangemPayNotificationInputPublisher,
            tangemPayBannerNotificationInputPublisher,
        ]

        publishers
            .combineLatest()
            .map { [bannerMapper] inputs in
                bannerMapper.mapItems(inputs)
            }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$items)
    }
}
