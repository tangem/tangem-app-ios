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

    private var bag = Set<AnyCancellable>()

    init(
        userWalletNotificationManager: NotificationManager,
        tokensNotificationManager: NotificationManager,
        bannerNotificationManager: NotificationManager?,
        tangemPayNotificationManager: NotificationManager
    ) {
        bind(
            userWalletNotificationManager: userWalletNotificationManager,
            tokensNotificationManager: tokensNotificationManager,
            bannerNotificationManager: bannerNotificationManager,
            tangemPayNotificationManager: tangemPayNotificationManager
        )
    }
}

private extension NotificationBannerItemsProvider {
    func bind(
        userWalletNotificationManager: NotificationManager,
        tokensNotificationManager: NotificationManager,
        bannerNotificationManager: NotificationManager?,
        tangemPayNotificationManager: NotificationManager,
    ) {
        let userWalletPublisher = userWalletNotificationManager
            .notificationPublisher
            .removeDuplicates()

        let tokensPublisher = tokensNotificationManager
            .notificationPublisher
            .removeDuplicates()

        let bannerPublisher = bannerNotificationManager?
            .notificationPublisher
            .removeDuplicates()
            .eraseToAnyPublisher() ?? Just([]).eraseToAnyPublisher()

        let tangemPayPublisher = tangemPayNotificationManager
            .notificationPublisher
            .removeDuplicates()

        Publishers
            .CombineLatest4(
                userWalletPublisher,
                tokensPublisher,
                bannerPublisher,
                tangemPayPublisher
            )
            .map {
                MultiWalletNotificationBannerMapper().mapItems(
                    $0.0, $0.1, $0.2, $0.3
                )
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$items)
    }
}
