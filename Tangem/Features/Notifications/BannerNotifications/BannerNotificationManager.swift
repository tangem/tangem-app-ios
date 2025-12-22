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
import TangemExpress
import TangemLocalization

class BannerNotificationManager {
    @Injected(\.bannerPromotionService) private var bannerPromotionService: BannerPromotionService
    @Injected(\.onrampRepository) private var onrampRepository: OnrampRepository

    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])
    private weak var delegate: NotificationTapDelegate?

    private let userWalletInfo: UserWalletInfo
    private let placement: BannerPromotionPlacement

    private let analyticsService: NotificationsAnalyticsService

    private let activePromotions: CurrentValueSubject<[ActivePromotionInfo], Never> = .init([])
    private var promotionUpdateTasks: [PromotionProgramName: Task<Void, Error>] = [:]
    private var analyticsSubscription: AnyCancellable?
    private var activePromotionSubscription: AnyCancellable?

    init(
        userWalletInfo: UserWalletInfo,
        placement: BannerPromotionPlacement
    ) {
        self.userWalletInfo = userWalletInfo
        self.placement = placement

        analyticsService = NotificationsAnalyticsService(userWalletId: userWalletInfo.id)

        bind()
        load()
    }

    private func load() {
        switch placement {
        case .main:
            loadActivePromotions(programNames: [.visaWaitlist, .blackFriday, .onePlusOne])
        case .tokenDetails:
            break
        }
    }

    private func bind() {
        analyticsSubscription = notificationPublisher
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { manager, notifications in
                manager.analyticsService.sendEventsIfNeeded(for: notifications)
            })

        activePromotionSubscription = activePromotions
            .withWeakCaptureOf(self)
            .flatMapLatest { manager, activePromotions -> AnyPublisher<[NotificationViewInput], Never> in
                guard !activePromotions.isEmpty else {
                    return Just([]).eraseToAnyPublisher()
                }

                let eventPublishers = activePromotions.map { promotion in
                    manager.makeEvent(promotion: promotion)
                        .first()
                        .withWeakCaptureOf(manager)
                        .map { manager, event -> NotificationViewInput? in
                            event.flatMap { manager.makeNotificationViewInput(event: $0) }
                        }
                }

                return Publishers.MergeMany(eventPublishers)
                    .collect()
                    .map { $0.compactMap { $0 } }
                    .receiveOnMain()
                    .eraseToAnyPublisher()
            }
            .assign(to: \.notificationInputsSubject.value, on: self, ownership: .weak)
    }

    private func loadActivePromotions(programNames: [PromotionProgramName]) {
        // Cancel previous tasks
        promotionUpdateTasks.values.forEach { $0.cancel() }
        promotionUpdateTasks.removeAll()

        // Load each promotion independently
        for programName in programNames {
            let task = runTask(in: self) { manager in
                guard let promotion = await manager.bannerPromotionService.activePromotion(
                    promotion: programName,
                    on: manager.placement
                ) else {
                    await runOnMain {
                        manager.removePromotion(programName: programName)
                    }
                    return
                }

                try Task.checkCancellation()
                await runOnMain {
                    manager.addOrUpdatePromotion(promotion)
                }
            }
            promotionUpdateTasks[programName] = task
        }
    }

    private func addOrUpdatePromotion(_ promotion: ActivePromotionInfo) {
        var currentPromotions = activePromotions.value
        // Remove existing promotion with the same name if exists
        currentPromotions.removeAll { $0.bannerPromotion == promotion.bannerPromotion }
        // Add new promotion
        currentPromotions.append(promotion)
        activePromotions.send(currentPromotions)
    }

    private func removePromotion(programName: PromotionProgramName) {
        var currentPromotions = activePromotions.value
        currentPromotions.removeAll { $0.bannerPromotion == programName }
        activePromotions.send(currentPromotions)
    }

    private func makeNotificationViewInput(event: BannerNotificationEvent) -> NotificationViewInput? {
        let buttonAction: NotificationView.NotificationButtonTapAction = { [weak self] id, action in
            self?.delegate?.didTapNotification(with: id, action: action)

            switch event.programName {
            case .visaWaitlist:
                Analytics.log(event: .promotionButtonJoinNow, params: event.analytics.analyticsParams)
            case .blackFriday, .onePlusOne:
                var params = event.analytics.analyticsParams
                params[.action] = Analytics.ParameterValue.clicked.rawValue
                Analytics.log(event: .promotionBannerClicked, params: params)
            }
        }

        let dismissAction: NotificationView.NotificationAction = { [weak self, placement] id in
            self?.bannerPromotionService.hide(promotion: event.programName, on: placement)
            self?.dismissNotification(with: id)

            switch event.programName {
            case .visaWaitlist:
                Analytics.log(event: .promotionButtonClose, params: event.analytics.analyticsParams)
            case .blackFriday, .onePlusOne:
                var params = event.analytics.analyticsParams
                params[.action] = Analytics.ParameterValue.closed.rawValue
                Analytics.log(event: .promotionBannerClicked, params: params)
            }
        }

        let input = NotificationsFactory()
            .buildNotificationInput(for: event, buttonAction: buttonAction, dismissAction: dismissAction)

        return input
    }

    private func makeEvent(promotion: ActivePromotionInfo) -> AnyPublisher<BannerNotificationEvent?, Never> {
        let analytics = BannerNotificationEventAnalyticsParamsBuilder(programName: promotion.bannerPromotion, placement: placement)

        return event(
            promotion: promotion,
            analytics: analytics
        )
    }

    private func event(
        promotion: ActivePromotionInfo,
        analytics: BannerNotificationEventAnalyticsParamsBuilder
    ) -> AnyPublisher<BannerNotificationEvent?, Never> {
        let buttonAction: NotificationButtonAction? = promotion.link.map { link in
            .init(.openLink(
                promotionLink: link,
                buttonTitle: promotion.bannerPromotion.buttonTitle
            ))
        }

        let event = BannerNotificationEvent(
            programName: promotion.bannerPromotion,
            analytics: analytics,
            buttonAction: buttonAction
        )

        return .just(output: event)
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
        var currentInputs = notificationInputsSubject.value
        currentInputs.removeAll { $0.id == id }
        notificationInputsSubject.send(currentInputs)
    }
}
