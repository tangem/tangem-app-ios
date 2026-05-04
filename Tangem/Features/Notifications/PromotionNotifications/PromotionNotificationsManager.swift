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
    @Injected(\.incomingActionHandler) private var incomingActionHandler: IncomingActionHandler

    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])

    private let userWalletId: UserWalletId
    private let placement: PromotionPlacement

    private var activePromotionSubscription: AnyCancellable?

    init(userWalletId: UserWalletId, placement: PromotionPlacement) {
        self.userWalletId = userWalletId
        self.placement = placement

        bind()
    }
}

// MARK: - Private

private extension CommonPromotionNotificationsManager {
    func bind() {
        activePromotionSubscription = promotionRepository
            .promotionsPublisher(userWalletId: userWalletId, placeholder: placement)
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
        await promotionRepository.loadPromotions(userWalletId: userWalletId)
    }

    func hide(promotion: Promotion) {
        Task { await promotionRepository.hidePromotion(userWalletId: userWalletId, displayId: promotion.id) }
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
