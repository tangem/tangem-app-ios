//
//  SwapMarketingBannerNotificationManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class SwapMarketingBannerNotificationManager {
    @Injected(\.incomingActionHandler) private var incomingActionHandler: IncomingActionHandler

    private let service = MarketingBannerService()
    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])
    private let linkedBannersSubject = CurrentValueSubject<[MarketingBanner], Never>([])
    private var subscription: AnyCancellable?
}

// MARK: - Setup

extension SwapMarketingBannerNotificationManager {
    func setup(
        sourceTokenInput: SendSourceTokenInput,
        sourceTokenAmountInput: SendSourceTokenAmountInput,
        receiveTokenInput: SendReceiveTokenInput
    ) {
        guard FeatureProvider.isAvailable(.marketingBanners) else {
            return
        }

        let requests = Publishers.CombineLatest3(
            sourceTokenInput.sourceTokenPublisher,
            receiveTokenInput.receiveTokenPublisher,
            sourceTokenAmountInput.sourceAmountPublisher
        )
        .map { source, receive, amount -> SwapMarketingBannerRequest? in
            guard let source = source.value, let receive = receive.value else {
                return nil
            }

            return SwapMarketingBannerRequest(
                source: source.tokenItem,
                destination: receive.tokenItem,
                sourceAmount: amount.value?.crypto
            )
        }
        .eraseToAnyPublisher()

        subscription = service.bannerPublisher(for: requests)
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { manager, banners in
                manager.notificationInputsSubject.send(banners.standalone.map { [manager.makeInput(for: $0)] } ?? [])
                manager.linkedBannersSubject.send(banners.linked)
            }
    }
}

// MARK: - Private

private extension SwapMarketingBannerNotificationManager {
    func makeInput(for banner: MarketingBanner) -> NotificationViewInput {
        let event = MarketingBannerNotificationEvent(banner: banner)

        let dismissAction: NotificationView.NotificationAction = { [weak self] id in
            self?.dismissNotification(with: id)
        }

        let style: NotificationView.Style = switch banner.action {
        case .deeplink(let url):
            .tappable(hasChevron: true) { [weak self] _ in
                _ = self?.incomingActionHandler.handleIncomingURL(url)
            }
        case .none:
            .plain
        }

        return NotificationViewInput(
            style: style,
            severity: event.severity,
            settings: .init(event: event, dismissAction: banner.isDismissible ? dismissAction : nil)
        )
    }
}

// MARK: - NotificationManager

extension SwapMarketingBannerNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {}

    func dismissNotification(with id: NotificationViewId) {
        notificationInputsSubject.value.removeAll { $0.id == id }
    }
}

// MARK: - LinkedMarketingBannerProviding

extension SwapMarketingBannerNotificationManager: LinkedMarketingBannerProviding {
    // [REDACTED_TODO_COMMENT]
    var linkedBannersPublisher: AnyPublisher<[MarketingBanner], Never> {
        linkedBannersSubject.eraseToAnyPublisher()
    }
}
