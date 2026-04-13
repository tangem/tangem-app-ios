//
//  PromotionNotificationsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class PromotionNotificationsViewModel: ObservableObject {
    @Published private(set) var notificationInputs: [NotificationViewInput] = []

    private let promotionNotificationsManager: PromotionNotificationsManager
    private var carouselIndexHasChangedTracked = false

    init(promotionNotificationsManager: PromotionNotificationsManager) {
        self.promotionNotificationsManager = promotionNotificationsManager
        bind()
    }

    func carouselIndexHasChanged(index: Int) {
        guard !carouselIndexHasChangedTracked else {
            return
        }

        guard let notification = notificationInputs[safe: index] else {
            return
        }

        Analytics.log(
            event: .promotionBannerCarouselScrolled,
            params: notification.settings.event.analyticsParams
        )
        carouselIndexHasChangedTracked = true
    }

    private func bind() {
        promotionNotificationsManager
            .notificationPublisher
            .receiveOnMain()
            .removeDuplicates()
            .assign(to: &$notificationInputs)
    }
}
