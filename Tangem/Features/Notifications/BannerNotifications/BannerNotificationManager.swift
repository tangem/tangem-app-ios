//
//  BannerNotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

class BannerNotificationManager {
    @Injected(\.bannerPromotionService) private var bannerPromotionService: BannerPromotionService

    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])
    private weak var delegate: NotificationTapDelegate?

    private let userWalletId: UserWalletId
    private let placement: BannerPromotionPlacement

    private let analyticsService = NotificationsAnalyticsService()
    private var promotionUpdateTask: Task<Void, Error>?

    init(userWalletId: UserWalletId, placement: BannerPromotionPlacement, contextDataProvider: AnalyticsContextDataProvider?) {
        self.userWalletId = userWalletId
        self.placement = placement

        analyticsService.setup(with: self, contextDataProvider: contextDataProvider)
        setup()
    }

    private func setup() {
        switch placement {
        case .main where AppSettings.shared.userWalletIdsWithRing.contains(userWalletId.stringValue):
            loadActivePromotionInfo(programName: .ring)
        case .main:
            loadActivePromotionInfo(programName: .onrampSEPAWithMercuryo)
        case .tokenDetails:
            break
        }
    }

    private func loadActivePromotionInfo(programName: PromotionProgramName) {
        promotionUpdateTask?.cancel()
        promotionUpdateTask = runTask(in: self) { manager in
            guard let promotion = await manager.bannerPromotionService.activePromotion(promotion: programName, on: manager.placement) else {
                await runOnMain {
                    manager.notificationInputsSubject.value.removeAll { $0.id == programName.hashValue }
                }
                return
            }

            try Task.checkCancellation()

            await runOnMain {
                manager.setupNotification(promotion: promotion)
            }
        }
    }

    private func setupNotification(promotion: ActivePromotionInfo) {
        let analytics = BannerNotificationEventAnalyticsParamsBuilder(programName: promotion.bannerPromotion, placement: placement)

        let buttonAction: NotificationView.NotificationButtonTapAction = { [weak self, placement] id, action in
            self?.delegate?.didTapNotification(with: id, action: action)

            if promotion.bannerPromotion.shouldHideWhenAction {
                self?.bannerPromotionService.hide(promotion: promotion.bannerPromotion, on: placement)
                self?.dismissNotification(with: id)
            }

            var params = analytics.analyticsParams
            params[.action] = Analytics.ParameterValue.clicked.rawValue
            Analytics.log(event: .promotionBannerClicked, params: params)
        }

        let dismissAction: NotificationView.NotificationAction = { [weak self, placement] id in
            self?.bannerPromotionService.hide(promotion: promotion.bannerPromotion, on: placement)
            self?.dismissNotification(with: id)

            var params = analytics.analyticsParams
            params[.action] = Analytics.ParameterValue.closed.rawValue
            Analytics.log(event: .promotionBannerClicked, params: params)
        }

        guard let event = makeEvent(promotion: promotion, analytics: analytics) else {
            notificationInputsSubject.value.removeAll { $0.id == promotion.bannerPromotion.hashValue }
            return
        }

        let input = NotificationsFactory()
            .buildNotificationInput(for: event, buttonAction: buttonAction, dismissAction: dismissAction)

        guard !notificationInputsSubject.value.contains(where: { $0.id == input.id }) else {
            return
        }

        notificationInputsSubject.value.insert(input, at: 0)
    }

    private func makeEvent(promotion: ActivePromotionInfo, analytics: BannerNotificationEventAnalyticsParamsBuilder) -> BannerNotificationEvent? {
        switch promotion.bannerPromotion {
        case .ring:
            if let link = promotion.link {
                return BannerNotificationEvent(
                    programName: promotion.bannerPromotion,
                    analytics: analytics,
                    buttonAction: .init(.openLink(promotionLink: link, buttonTitle: ""))
                )
            }

        case .onrampSEPAWithMercuryo:
            let builder = PredefinedOnrampParametersBuilder()
            if let (walletModel, parameters) = builder.prepare(userWalletId: userWalletId) {
                return BannerNotificationEvent(
                    programName: promotion.bannerPromotion,
                    analytics: analytics,
                    buttonAction: .init(.openBuyCrypto(walletModel: walletModel, parameters: parameters))
                )
            }
        }

        return nil
    }
}

// MARK: - NotificationManager

extension BannerNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate
    }

    func dismissNotification(with id: NotificationViewId) {
        notificationInputsSubject.value.removeAll(where: { $0.id == id })
    }
}
