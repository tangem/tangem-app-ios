//
//  SwapMarketingBannerManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class SwapMarketingBannerManager {
    @Injected(\.incomingActionHandler) private var incomingActionHandler: IncomingActionHandler

    private let service = MarketingBannerService()
    private let standaloneBannersSubject = CurrentValueSubject<[StandaloneMarketingBannerViewModel], Never>([])
    private let linkedBannersSubject = CurrentValueSubject<[MarketingBanner], Never>([])
    private var subscription: AnyCancellable?
}

// MARK: - Setup

extension SwapMarketingBannerManager {
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
                manager.standaloneBannersSubject.send(banners.standalone.map { manager.makeStandaloneViewModel(for: $0) })
                manager.linkedBannersSubject.send(banners.linked)
            }
    }
}

// MARK: - Private

private extension SwapMarketingBannerManager {
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

extension SwapMarketingBannerManager {
    var standaloneBannersPublisher: AnyPublisher<[StandaloneMarketingBannerViewModel], Never> {
        standaloneBannersSubject.eraseToAnyPublisher()
    }
}

// MARK: - LinkedMarketingBannerProviding

extension SwapMarketingBannerManager: LinkedMarketingBannerProviding {
    // [REDACTED_TODO_COMMENT]
    var linkedBannersPublisher: AnyPublisher<[MarketingBanner], Never> {
        linkedBannersSubject.eraseToAnyPublisher()
    }
}
