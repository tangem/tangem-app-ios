//
//  PromotionNotificationsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol PromotionNotificationsManager: NotificationManager {
    func loadPromotions() async
}

class CommonPromotionNotificationsManager {
    @Injected(\.promotionRepository) private var promotionRepository: PromotionRepository
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.incomingActionHandler) private var incomingActionHandler: IncomingActionHandler

    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])

    private let placement: PromotionPlacement
    private var analyticsServices: ThreadSafeContainer<[UserWalletId: NotificationsAnalyticsService]> = [:]

    private var analyticsSubscription: AnyCancellable?
    private var activePromotionSubscription: AnyCancellable?

    init(placement: PromotionPlacement) {
        self.placement = placement

        bind()
    }

    private func analyticsService(for userWalletId: UserWalletId) -> NotificationsAnalyticsService {
        if let analyticsService = analyticsServices.read()[userWalletId] {
            return analyticsService
        }

        let analyticsService = NotificationsAnalyticsService(userWalletId: userWalletId)
        analyticsServices.mutate { $0[userWalletId] = analyticsService }
        return analyticsService
    }
}

// MARK: - Private

private extension CommonPromotionNotificationsManager {
    func bind() {
        analyticsSubscription = notificationPublisher
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { manager, notifications in
                guard let userWalletId = manager.userWalletRepository.selectedModel?.userWalletId else {
                    return
                }

                manager.analyticsService(for: userWalletId).sendEventsIfNeeded(for: notifications)
            })

        activePromotionSubscription = promotionRepository
            .promotionsPublisher(placeholder: placement)
            .withWeakCaptureOf(self)
            .map { $0.mapToPromotionNotificationEvents(items: $1) }
            .withWeakCaptureOf(self)
            .map { $0.mapToNotificationViewInputs(events: $1) }
            .receiveOnMain()
            .removeDuplicates()
            .assign(to: \.notificationInputsSubject.value, on: self, ownership: .weak)
    }

    func mapToPromotionNotificationEvents(items: [Promotion]) -> [PromotionNotificationEvent] {
        items.map { mapToPromotionNotificationEvent(item: $0) }
    }

    func mapToPromotionNotificationEvent(item: Promotion) -> PromotionNotificationEvent {
        let buttonAction: NotificationButtonAction? = {
            guard item.buttonEnabled, let deeplink = item.deeplink else {
                return nil
            }

            return NotificationButtonAction(.openDeeplink(
                url: deeplink,
                buttonTitle: item.buttonText ?? ""
            ))
        }()

        return PromotionNotificationEvent(promotion: item, buttonAction: buttonAction)
    }

    func mapToNotificationViewInputs(events: [PromotionNotificationEvent]) -> [NotificationViewInput] {
        events.map { mapToNotificationViewInput(event: $0) }
    }

    func mapToNotificationViewInput(event: PromotionNotificationEvent) -> NotificationViewInput {
        let buttonAction: NotificationView.NotificationButtonTapAction = { [weak self] id, action in
            self?.didTapNotification(with: id, action: action)

            Analytics.log(event: .promotionBannerButtonClicked, params: event.analyticsParams)
        }

        let dismissAction: NotificationView.NotificationAction = { [weak self] id in
            self?.dismissNotification(with: id)
            self?.hide(promotion: event.promotion)

            Analytics.log(event: .promotionBannerDismissed, params: event.analyticsParams)
        }

        let input = NotificationsFactory()
            .buildNotificationInput(for: event, buttonAction: buttonAction, dismissAction: dismissAction)

        return input
    }
}

// MARK: - Actions

extension CommonPromotionNotificationsManager {
    func loadPromotions() async {
        await promotionRepository.loadPromotions()
    }

    func hide(promotion: PromotionsDTO.Load.Item) {
        Task {
            do {
                try await promotionRepository.hidePromotion(displayId: promotion.id)
            } catch {
                PromotionLogger.error("Hide promotion error: ", error: error)
            }
        }
    }
}

// MARK: - NotificationTapDelegate

extension CommonPromotionNotificationsManager: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .openDeeplink(let url, _):
            let handled = incomingActionHandler.handleIncomingURL(url)
            PromotionLogger.info("Promotion deeplink handled: \(handled)")
        default:
            break
        }
    }
}

// MARK: - PromotionNotificationsManager

extension CommonPromotionNotificationsManager: PromotionNotificationsManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        assertionFailure("Handles deeplinks internally, no external delegate needed")
    }

    func dismissNotification(with id: NotificationViewId) {
        var currentInputs = notificationInputsSubject.value
        currentInputs.removeAll { $0.id == id }
        notificationInputsSubject.send(currentInputs)
    }
}
