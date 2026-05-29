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

    weak var amountInput: OnrampAmountInput?

    private let balanceFormatter = BalanceFormatter()

    init(
        geoEligibilityService: GeoEligibilityService,
        tokenItem: TokenItem,
        amountInput: OnrampAmountInput,
        applePayPresenter: any OnrampApplePayPresenting,
        countryCode: String = Locale.current.region?.identifier ?? "US"
    ) {
        self.geoEligibilityService = geoEligibilityService
        self.tokenItem = tokenItem
        self.countryCode = countryCode
        self.amountInput = amountInput
        self.applePayPresenter = applePayPresenter
    }

    func make(
        provider: OnrampProvider,
        onWillBuy: @escaping () -> Void,
        onWidgetBuy: @escaping () -> Void
    ) -> OnrampOfferViewModel.BuyAction {
        // Native Apple Pay is restricted in some regions; fall back to the web widget there.
        guard geoEligibilityService.isApplePayAllowed else {
            return widget(onWillBuy: onWillBuy, onWidgetBuy: onWidgetBuy)
        }

        // The provider has to declare Apple Pay as its payment method.
        guard provider.paymentMethod.type == .applePay else {
            return widget(onWillBuy: onWillBuy, onWidgetBuy: onWidgetBuy)
        }

        // Backend must mark the quote as native-payment-eligible and return a usable `quoteId`.
        guard let quote = provider.quote,
              quote.nativePaymentAvailable,
              quote.quoteId != nil else {
            return widget(onWillBuy: onWillBuy, onWidgetBuy: onWidgetBuy)
        }

        // Need a concrete amount and currency code to build the Apple Pay summary item.
        guard let amount = provider.amount,
              let currencyCode = amountInput?.fiatCurrency?.identity.code else {
            return widget(onWillBuy: onWillBuy, onWidgetBuy: onWidgetBuy)
        }

        guard let merchantIdentifier = OnrampApplePayConstants.merchantIdentifier(forProviderId: provider.provider.id) else {
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

        return .nativeApplePay { [applePayPresenter] in
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
