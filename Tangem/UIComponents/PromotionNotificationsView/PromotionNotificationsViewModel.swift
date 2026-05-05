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
    private var currentIndex: Int = 0
    private var isViewVisible = false
    private var carouselScrolledTracked = false
    private var trackedNotificationIds: Set<NotificationViewId> = []
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

    func onScreenVisibilityChange(isVisible: Bool) {
        isViewVisible = isVisible

        if isVisible {
            trackBannerShownIfNeeded()
        }
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
        guard isViewVisible else {
            return
        }

        guard let notification = notificationInputs[safe: currentIndex] else {
            return
        }

        guard !trackedNotificationIds.contains(notification.id) else {
            return
        }

        trackedNotificationIds.insert(notification.id)
        Analytics.log(
            event: .promotionBannerBannerShown,
            params: notification.settings.event.analyticsParams
        )
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
