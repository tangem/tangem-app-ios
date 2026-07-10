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
    private let standaloneBannersSubject = CurrentValueSubject<[StandaloneMarketingBannerViewModel], Never>([])
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

        let requests = amountInput.fiatCurrencyPublisher
            .map { fiatCurrency -> OnrampMarketingBannerRequest? in
                OnrampMarketingBannerRequest(
                    destination: tokenItem,
                    fiatCurrencyCode: fiatCurrency?.identity.code
                )
            }
            .eraseToAnyPublisher()

        let amount = providersInput.selectedOnrampProviderPublisher
            .map { provider -> MarketingBannerAmount? in
                guard let value = provider?.value?.quote?.expectedAmount, let currencyId = tokenItem.currencyId else {
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
                manager.standaloneBannersSubject.send(banners.standalone.map { manager.makeStandaloneViewModel(for: $0) })
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

    func makeStandaloneViewModel(for banner: MarketingBanner) -> StandaloneMarketingBannerViewModel {
        let action: (() -> Void)? = switch banner.action {
        case .deeplink(let url):
            { [incomingActionHandler] in _ = incomingActionHandler.handleIncomingURL(url) }
        case .none:
            nil
        }

        return StandaloneMarketingBannerViewModel(
            id: banner.id,
            title: banner.text,
            iconURL: banner.iconURL,
            isDismissible: banner.isDismissible,
            action: action,
            dismiss: banner.isDismissible ? { [weak self] in self?.dismissStandaloneBanner(id: banner.id) } : nil
        )
    }

    func dismissStandaloneBanner(id: Int) {
        standaloneBannersSubject.value.removeAll { $0.id == id }
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

// MARK: - Standalone banners

extension OnrampMarketingBannerNotificationManager {
    var standaloneBannersPublisher: AnyPublisher<[StandaloneMarketingBannerViewModel], Never> {
        standaloneBannersSubject.eraseToAnyPublisher()
    }
}

// MARK: - LinkedMarketingBannerProviding

extension OnrampMarketingBannerNotificationManager: LinkedMarketingBannerProviding {
    var linkedBannersPublisher: AnyPublisher<[MarketingBanner], Never> {
        linkedBannersSubject.eraseToAnyPublisher()
    }
}
