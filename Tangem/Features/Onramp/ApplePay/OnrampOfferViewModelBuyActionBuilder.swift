//
//  OnrampOfferViewModelBuyActionBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import PassKit
import TangemExpress

struct OnrampOfferViewModelBuyActionBuilder {
    let geoEligibilityService: GeoEligibilityService
    let tokenItem: TokenItem
    let countryCode: String
    let applePayPresenter: any OnrampApplePayPresenting
    let analyticsLogger: any SendOnrampNAPAnalyticsLogger

    weak var amountInput: OnrampAmountInput?

    private let balanceFormatter = BalanceFormatter()

    init(
        geoEligibilityService: GeoEligibilityService,
        tokenItem: TokenItem,
        amountInput: OnrampAmountInput,
        applePayPresenter: any OnrampApplePayPresenting,
        analyticsLogger: any SendOnrampNAPAnalyticsLogger,
        countryCode: String = Locale.current.region?.identifier ?? "US"
    ) {
        self.geoEligibilityService = geoEligibilityService
        self.tokenItem = tokenItem
        self.countryCode = countryCode
        self.amountInput = amountInput
        self.applePayPresenter = applePayPresenter
        self.analyticsLogger = analyticsLogger
    }

    func make(
        provider: OnrampProvider,
        onWillBuy: @escaping () -> Void,
        onWidgetBuy: @escaping () -> Void
    ) -> OnrampOfferViewModel.BuyAction {
        let providerId = provider.provider.id

        // Native Apple Pay is restricted in some regions; fall back to the web widget there.
        guard geoEligibilityService.isApplePayAllowed else {
            OnrampLogger.info("[NAP] unavailable for provider \(providerId): Apple Pay restricted (countryCode=\(countryCode))")
            return widget(onWillBuy: onWillBuy, onWidgetBuy: onWidgetBuy)
        }

        // The provider has to declare Apple Pay as its payment method.
        guard provider.paymentMethod.type == .applePay else {
            OnrampLogger.info("[NAP] unavailable for provider \(providerId): payment method is not Apple Pay (\(provider.paymentMethod.type))")
            return widget(onWillBuy: onWillBuy, onWidgetBuy: onWidgetBuy)
        }

        // Backend must mark the quote as native-payment-eligible and return a usable `quoteId`.
        guard let quote = provider.quote else {
            OnrampLogger.info("[NAP] unavailable for provider \(providerId): no loaded quote (state \(provider.state))")
            return widget(onWillBuy: onWillBuy, onWidgetBuy: onWidgetBuy)
        }

        guard quote.nativePaymentAvailable else {
            OnrampLogger.info("[NAP] unavailable for provider \(providerId): quote nativePaymentAvailable=false")
            return widget(onWillBuy: onWillBuy, onWidgetBuy: onWidgetBuy)
        }

        guard quote.quoteId != nil else {
            OnrampLogger.info("[NAP] unavailable for provider \(providerId): quote missing quoteId")
            return widget(onWillBuy: onWillBuy, onWidgetBuy: onWidgetBuy)
        }

        // Need a concrete amount and currency code to build the Apple Pay summary item.
        guard let amount = provider.amount else {
            OnrampLogger.info("[NAP] unavailable for provider \(providerId): missing amount")
            return widget(onWillBuy: onWillBuy, onWidgetBuy: onWidgetBuy)
        }

        guard let currencyCode = amountInput?.fiatCurrency?.identity.code else {
            OnrampLogger.info("[NAP] unavailable for provider \(providerId): missing fiat currency code")
            return widget(onWillBuy: onWillBuy, onWidgetBuy: onWidgetBuy)
        }

        guard let merchantIdentifier = OnrampApplePayConstants.merchantIdentifier(forProviderId: providerId) else {
            OnrampLogger.info("[NAP] unavailable for provider \(providerId): no merchant identifier configured")
            return widget(onWillBuy: onWillBuy, onWidgetBuy: onWidgetBuy)
        }

        let summaryItemLabel = balanceFormatter.formatCryptoBalance(
            quote.expectedAmount,
            currencyCode: tokenItem.currencySymbol
        )

        let request = OnrampApplePayUtils.makePaymentRequest(
            amount: amount,
            currencyCode: currencyCode,
            countryCode: countryCode,
            summaryItemLabel: summaryItemLabel,
            merchantIdentifier: merchantIdentifier
        )

        return .nativeApplePay { [applePayPresenter, analyticsLogger] in
            analyticsLogger.logOnrampButtonNAP(amount: amount, currencyCode: currencyCode)
            applePayPresenter.present(request: request, provider: provider, onWillBuy: onWillBuy)
        }
    }

    private func widget(
        onWillBuy: @escaping () -> Void,
        onWidgetBuy: @escaping () -> Void
    ) -> OnrampOfferViewModel.BuyAction {
        .button {
            onWillBuy()
            onWidgetBuy()
        }
    }
}
