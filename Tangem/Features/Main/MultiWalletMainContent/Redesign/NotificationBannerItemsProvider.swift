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

    init(managers: [NotificationManager]) {
        let publishers = managers.map {
            $0.notificationPublisher
                .removeDuplicates()
                .eraseToAnyPublisher()
        }

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
