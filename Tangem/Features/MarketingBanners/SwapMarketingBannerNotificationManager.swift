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

        let requests = Publishers.CombineLatest(
            sourceTokenInput.sourceTokenPublisher,
            receiveTokenInput.receiveTokenPublisher
        )
        .map { source, receive -> SwapMarketingBannerRequest? in
            guard let source = source.value, let receive = receive.value else {
                return nil
            }

            return SwapMarketingBannerRequest(
                source: source.tokenItem,
                destination: receive.tokenItem
            )
        }
        .eraseToAnyPublisher()

        let amount = Publishers.CombineLatest(
            sourceTokenInput.sourceTokenPublisher,
            sourceTokenAmountInput.sourceAmountPublisher
        )
        .map { source, amount -> MarketingBannerAmount? in
            guard let source = source.value,
                  let value = amount.value?.crypto,
                  let currencyId = source.tokenItem.currencyId else {
                return nil
            }

            return MarketingBannerAmount(value: value, currencyId: currencyId)
        }
        .eraseToAnyPublisher()

        subscription = service.bannerPublisher(for: requests, amount: amount)
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { manager, banners in
                manager.notificationInputsSubject.send(banners.standalone.map { manager.makeInput(for: $0) })
                manager.linkedBannersSubject.send(banners.linked)
            }
    }
}

// MARK: - Private

private extension SwapMarketingBannerNotificationManager {
    func makeInput(for banner: MarketingBanner) -> NotificationViewInput {
        MarketingBannerNotificationInputFactory.makeInput(
            for: banner,
            incomingActionHandler: incomingActionHandler
        ) { [weak self] id in
            self?.dismissNotification(with: id)
        }
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
