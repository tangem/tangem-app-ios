//
//  MarketingBannerManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class MarketingBannerManager {
    @Injected(\.incomingActionHandler) private var incomingActionHandler: IncomingActionHandler

    private let standaloneBannersSubject = CurrentValueSubject<[StandaloneMarketingBannerViewModel], Never>([])
    private let linkedBannersSubject = CurrentValueSubject<[MarketingBanner], Never>([])
    private var subscription: AnyCancellable?
}

// MARK: - Setup

extension MarketingBannerManager {
    func setup(bannersPublisher: AnyPublisher<MarketingBanners, Never>) {
        subscription = bannersPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { manager, banners in
                manager.standaloneBannersSubject.send(banners.standalone.map { manager.makeStandaloneViewModel(for: $0) })
                manager.linkedBannersSubject.send(banners.linked)
            }
    }
}

// MARK: - Private

private extension MarketingBannerManager {
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
            dismiss: banner.isDismissible ? { HiddenMarketingCampaignsStorage.hide(campaignId: banner.id) } : nil
        )
    }
}

// MARK: - Standalone banners

extension MarketingBannerManager {
    var standaloneBannersPublisher: AnyPublisher<[StandaloneMarketingBannerViewModel], Never> {
        standaloneBannersSubject.eraseToAnyPublisher()
    }
}

// MARK: - LinkedMarketingBannerProviding

extension MarketingBannerManager: LinkedMarketingBannerProviding {
    // [REDACTED_TODO_COMMENT]
    var linkedBannersPublisher: AnyPublisher<[MarketingBanner], Never> {
        linkedBannersSubject.eraseToAnyPublisher()
    }
}
