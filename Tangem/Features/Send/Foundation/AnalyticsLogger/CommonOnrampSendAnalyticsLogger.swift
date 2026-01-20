//
//  CommonOnrampSendAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

class CommonOnrampSendAnalyticsLogger {
    private let tokenItem: TokenItem
    private let source: SendCoordinator.Source

    private weak var onrampProvidersInput: OnrampProvidersInput?

    init(tokenItem: TokenItem, source: SendCoordinator.Source) {
        self.tokenItem = tokenItem
        self.source = source
    }

    private func logOnrampButtonBuy(provider: OnrampProvider?) {
        guard let provider, let request = try? provider.makeOnrampQuotesRequestItem() else {
            return
        }

        Analytics.log(
            event: .onrampButtonBuy,
            params: [
                .provider: provider.provider.name,
                .currency: request.pairItem.fiatCurrency.identity.code,
                .token: tokenItem.currencySymbol,
            ]
        )
    }
}

// MARK: - SendBaseViewAnalyticsLogger

extension CommonOnrampSendAnalyticsLogger: OnrampSendAnalyticsLogger {
    func setup(onrampProvidersInput: any OnrampProvidersInput) {
        self.onrampProvidersInput = onrampProvidersInput
    }

    func logOnrampSelectedProvider(provider: OnrampProvider) {
        switch provider.state {
        case .restriction(.tooSmallAmount):
            Analytics.log(.onrampErrorMinAmount)
        case .restriction(.tooBigAmount):
            Analytics.log(.onrampErrorMaxAmount)
        case .loaded:
            Analytics.log(
                event: .onrampProviderCalculated,
                params: [
                    .token: tokenItem.currencySymbol,
                    .provider: provider.provider.name,
                    .paymentMethod: provider.paymentMethod.name,
                ]
            )
        default:
            break
        }
    }
}

// MARK: - SendBaseViewAnalyticsLogger

extension CommonOnrampSendAnalyticsLogger: SendBaseViewAnalyticsLogger {
    func logMainActionButton(type: SendMainButtonType, flow: SendFlowActionType) {
        switch (type, flow) {
        case (.action, .onramp):
            logOnrampButtonBuy(provider: onrampProvidersInput?.selectedOnrampProvider)
        default:
            break
        }
    }

    func logRequestSupport() {
        Analytics.log(.requestSupport, params: [.source: .send])
    }

    func logSendBaseViewOpened() {
        Analytics.log(event: .onrampBuyScreenOpened, params: [
            .source: source.analytics.rawValue,
            .token: tokenItem.currencySymbol,
        ], analyticsSystems: .all)
    }

    func logCloseButton(stepType: SendStepType, isAvailableToAction: Bool) {
        Analytics.log(.onrampButtonClose)
    }
}

// MARK: - SendOnrampOffersAnalyticsLogger

extension CommonOnrampSendAnalyticsLogger: SendOnrampOffersAnalyticsLogger {
    func logOnrampOfferButtonBuy(provider: OnrampProvider) {
        logOnrampButtonBuy(provider: provider)
    }

    func logOnrampRecentlyUsedClicked(provider: OnrampProvider) {
        Analytics.log(
            event: .onrampRecentlyUsedClicked,
            params: [
                .token: tokenItem.currencySymbol,
                .provider: provider.provider.name,
                .paymentMethod: provider.paymentMethod.name,
            ]
        )
    }

    func logOnrampBestRateClicked(provider: OnrampProvider) {
        Analytics.log(
            event: .onrampBestRateClicked,
            params: [
                .token: tokenItem.currencySymbol,
                .provider: provider.provider.name,
                .paymentMethod: provider.paymentMethod.name,
            ]
        )
    }

    func logOnrampFastestMethodClicked(provider: OnrampProvider) {
        Analytics.log(
            event: .onrampFastestMethodClicked,
            params: [
                .token: tokenItem.currencySymbol,
                .provider: provider.provider.name,
                .paymentMethod: provider.paymentMethod.name,
            ]
        )
    }

    func logOnrampButtonAllOffers() {
        Analytics.log(.onrampButtonAllOffers)
    }
}

// MARK: - SendOnrampProvidersAnalyticsLogger

extension CommonOnrampSendAnalyticsLogger: SendOnrampProvidersAnalyticsLogger {
    func logOnrampProvidersScreenOpened() {
        Analytics.log(.onrampProvidersScreenOpened)
    }

    func logOnrampProviderChosen(provider: ExpressProvider) {
        Analytics.log(event: .onrampProviderChosen, params: [
            .provider: provider.name,
            .token: tokenItem.currencySymbol,
        ])
    }
}

// MARK: - SendOnrampPaymentMethodAnalyticsLogger

extension CommonOnrampSendAnalyticsLogger: SendOnrampPaymentMethodAnalyticsLogger {
    func logOnrampPaymentMethodScreenOpened() {
        Analytics.log(.onrampPaymentMethodScreenOpened)
    }

    func logOnrampPaymentMethodChosen(paymentMethod: OnrampPaymentMethod) {
        Analytics.log(event: .onrampMethodChosen, params: [
            .paymentMethod: paymentMethod.name,
        ])
    }
}

// MARK: - SendFinishAnalyticsLogger

extension CommonOnrampSendAnalyticsLogger: SendFinishAnalyticsLogger {
    func logFinishStepOpened() {
        guard let provider = onrampProvidersInput?.selectedOnrampProvider,
              let request = try? provider.makeOnrampQuotesRequestItem() else {
            return
        }

        Analytics.log(event: .onrampBuyingInProgressScreenOpened, params: [
            .token: tokenItem.currencySymbol,
            .provider: provider.provider.name,
            .paymentMethod: provider.paymentMethod.name,
            .residence: request.pairItem.country.identity.name,
            .currency: request.pairItem.fiatCurrency.identity.code,
        ], analyticsSystems: .all)
    }

    func logShareButton() {}
    func logExploreButton() {}
}
