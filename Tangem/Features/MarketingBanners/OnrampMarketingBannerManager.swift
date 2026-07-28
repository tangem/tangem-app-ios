//
//  OnrampMarketingBannerManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress
import TangemFoundation

final class OnrampMarketingBannerManager {
    @Injected(\.incomingActionHandler) private var incomingActionHandler: IncomingActionHandler

    private let service = MarketingBannerService()
    private let standaloneBannersSubject = CurrentValueSubject<[StandaloneMarketingBannerViewModel], Never>([])
    private let linkedBannersSubject = CurrentValueSubject<[MarketingBanner], Never>([])
    private var subscription: AnyCancellable?
}

// MARK: - Setup

extension OnrampMarketingBannerManager {
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
                manager.standaloneBannersSubject.send(banners.standalone.map { manager.makeStandaloneViewModel(for: $0) })
                manager.linkedBannersSubject.send(banners.linked)
            }
    }
}

// MARK: - Private

private extension OnrampMarketingBannerManager {
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

extension OnrampMarketingBannerManager {
    var standaloneBannersPublisher: AnyPublisher<[StandaloneMarketingBannerViewModel], Never> {
        standaloneBannersSubject.eraseToAnyPublisher()
    }
}

// MARK: - LinkedMarketingBannerProviding

extension OnrampMarketingBannerManager: LinkedMarketingBannerProviding {
    var linkedBannersPublisher: AnyPublisher<[MarketingBanner], Never> {
        linkedBannersSubject.eraseToAnyPublisher()
    }
}
