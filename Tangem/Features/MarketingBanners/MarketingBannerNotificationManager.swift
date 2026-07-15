//
//  MarketingBannerNotificationManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class MarketingBannerNotificationManager {
    @Injected(\.incomingActionHandler) private var incomingActionHandler: IncomingActionHandler

    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])
    private let standaloneBannersSubject = CurrentValueSubject<[StandaloneMarketingBannerViewModel], Never>([])
    private let linkedBannersSubject = CurrentValueSubject<[MarketingBanner], Never>([])
    private var subscription: AnyCancellable?
}

// MARK: - Setup

extension MarketingBannerNotificationManager {
    func setup(bannersPublisher: AnyPublisher<MarketingBanners, Never>) {
        subscription = bannersPublisher
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

private extension MarketingBannerNotificationManager {
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

extension MarketingBannerNotificationManager: NotificationManager {
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

extension MarketingBannerNotificationManager {
    var standaloneBannersPublisher: AnyPublisher<[StandaloneMarketingBannerViewModel], Never> {
        standaloneBannersSubject.eraseToAnyPublisher()
    }
}

// MARK: - LinkedMarketingBannerProviding

extension MarketingBannerNotificationManager: LinkedMarketingBannerProviding {
    // [REDACTED_TODO_COMMENT]
    var linkedBannersPublisher: AnyPublisher<[MarketingBanner], Never> {
        linkedBannersSubject.eraseToAnyPublisher()
    }
}
