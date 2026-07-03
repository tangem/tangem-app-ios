//
//  OnrampMarketingBannerNotificationManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress
import TangemFoundation

final class OnrampMarketingBannerNotificationManager {
    @Injected(\.incomingActionHandler) private var incomingActionHandler: IncomingActionHandler

    private let service = MarketingBannerService()
    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])
    private let linkedBannersSubject = CurrentValueSubject<[MarketingBanner], Never>([])
    private var subscription: AnyCancellable?
}

// MARK: - Setup

extension OnrampMarketingBannerNotificationManager {
    func setup(
        tokenItem: TokenItem,
        amountInput: any OnrampAmountInput,
        providersInput: any OnrampProvidersInput
    ) {
        guard FeatureProvider.isAvailable(.marketingBanners) else {
            return
        }

        let requests = Publishers.CombineLatest(
            amountInput.fiatCurrencyPublisher,
            providersInput.selectedOnrampProviderPublisher
        )
        .map { fiatCurrency, provider -> OnrampMarketingBannerRequest? in
            OnrampMarketingBannerRequest(
                destination: tokenItem,
                expectedCryptoAmount: provider?.value?.quote?.expectedAmount,
                fiatCurrencyCode: fiatCurrency?.identity.code
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

private extension OnrampMarketingBannerNotificationManager {
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

extension OnrampMarketingBannerNotificationManager: NotificationManager {
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

extension OnrampMarketingBannerNotificationManager: LinkedMarketingBannerProviding {
    // [REDACTED_TODO_COMMENT]
    var linkedBannersPublisher: AnyPublisher<[MarketingBanner], Never> {
        linkedBannersSubject.eraseToAnyPublisher()
    }
}
