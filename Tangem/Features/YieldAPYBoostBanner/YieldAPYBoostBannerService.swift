//
//  YieldAPYBoostBannerService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class YieldAPYBoostBannerService {
    @Injected(\.incomingActionHandler) private var incomingActionHandler: IncomingActionHandler
    @Injected(\.yieldAPYBoostPromoRepository) private var promoRepository: YieldAPYBoostPromoRepository
    @Injected(\.tangemStoriesPresenter) private var tangemStoriesPresenter: any TangemStoriesPresenter

    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])
    private let userWalletId: UserWalletId

    init(userWalletId: UserWalletId) {
        self.userWalletId = userWalletId
        _ = runTask(in: self) { service in
            await service.loadBanner()
        }
    }

    private func loadBanner() async {
        let isDismissed = await MainActor.run {
            AppSettings.shared.yieldApyBoostHiddenPromos.contains(YieldAPYBoostPromoRepository.campaignName)
        }

        guard FeatureProvider.isAvailable(.yieldApyBoostPromo),
              !FeatureProvider.isAvailable(.redesign),
              !isDismissed
        else {
            notificationInputsSubject.send([])
            return
        }

        guard
            let campaign = await promoRepository.campaign(userWalletId: userWalletId.stringValue),
            (campaign.startDate ... campaign.endDate).contains(Date()),
            campaign.promoEnrollmentStatus == .notStarted
        else {
            notificationInputsSubject.send([])
            return
        }

        notificationInputsSubject.send([makeNotificationInput()])
    }
}

// MARK: - NotificationManager

extension YieldAPYBoostBannerService: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        assertionFailure("Handles deeplink internally, no external delegate needed")
    }

    func dismissNotification(with id: NotificationViewId) {
        if !AppSettings.shared.yieldApyBoostHiddenPromos.contains(YieldAPYBoostPromoRepository.campaignName) {
            AppSettings.shared.yieldApyBoostHiddenPromos.append(YieldAPYBoostPromoRepository.campaignName)
        }

        notificationInputsSubject.send([])
    }
}

// MARK: - Private

private extension YieldAPYBoostBannerService {
    func makeNotificationInput() -> NotificationViewInput {
        let buttonAction: NotificationView.NotificationButtonTapAction = { [tangemStoriesPresenter, incomingActionHandler] _, _ in
            Analytics.log(.mainScreenButtonExploreYieldMode)

            Task { @MainActor in
                tangemStoriesPresenter.present(
                    story: .yieldFirstActivationAPYBoostStory,
                    analyticsSource: .main,
                    presentCompletion: {
                        _ = incomingActionHandler.handleIncomingURL(YieldAPYBoostBannerNotificationEvent.deeplink)
                    }
                )
            }
        }

        let dismissAction: NotificationView.NotificationAction = { [weak self] id in
            self?.dismissNotification(with: id)
        }

        return NotificationsFactory().buildNotificationInput(
            for: YieldAPYBoostBannerNotificationEvent(),
            buttonAction: buttonAction,
            dismissAction: dismissAction
        )
    }
}
