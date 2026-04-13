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

    @Injected(\.promotionBannerShownTracker)
    private var promotionBannerShownTracker: PromotionBannerShownTracker

    private let promotionNotificationsManager: PromotionNotificationsManager
    private var currentIndex: Int = 0
    private var carouselScrolledTracked = false
    private var bag = Set<AnyCancellable>()

    init(promotionNotificationsManager: PromotionNotificationsManager) {
        self.promotionNotificationsManager = promotionNotificationsManager
        bind()
    }

    func carouselIndexHasChanged(index: Int) {
        currentIndex = index
        trackBannerShownIfNeeded()
        trackCarouselScrolledIfNeeded()
    }

    private func bind() {
        promotionNotificationsManager
            .notificationPublisher
            .receiveOnMain()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, inputs in
                viewModel.notificationInputs = inputs
                viewModel.trackBannerShownIfNeeded()
            }
            .store(in: &bag)
    }

    private func trackBannerShownIfNeeded() {
        guard let notification = notificationInputs[safe: currentIndex] else {
            return
        }

        guard !promotionBannerShownTracker.hasBeenShown(displayId: notification.id) else {
            return
        }

        Analytics.log(
            event: .promotionBannerBannerShown,
            params: notification.settings.event.analyticsParams
        )
        promotionBannerShownTracker.markAsShown(displayId: notification.id)
    }

    private func trackCarouselScrolledIfNeeded() {
        guard !carouselScrolledTracked, notificationInputs.count > 1 else {
            return
        }

        guard let notification = notificationInputs[safe: currentIndex] else {
            return
        }

        Analytics.log(
            event: .promotionBannerCarouselScrolled,
            params: notification.settings.event.analyticsParams
        )
        carouselScrolledTracked = true
    }
}
