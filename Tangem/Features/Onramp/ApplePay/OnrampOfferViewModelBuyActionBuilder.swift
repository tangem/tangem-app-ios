//
//  OnrampOfferViewModelBuyActionBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import PassKit
import SwiftUI
import TangemExpress

struct OnrampOfferViewModelBuyActionBuilder {
    let geoEligibilityService: GeoEligibilityService
    weak var amountInput: OnrampAmountInput?
    weak var authorizationHandler: ApplePayButtonPaymentAuthorizationHandler?

    private var countryCode: String { Locale.current.region?.identifier ?? "US" }

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

        let request = OnrampApplePayUtils.makePaymentRequest(
            amount: amount,
            currencyCode: currencyCode,
            countryCode: countryCode
        )

        return .nativeApplePay(request: request) { [self, onWillBuy] phase in
            handle(phase: phase, provider: provider, onWillBuy: onWillBuy)
        }
    }

    private func handle(
        phase: PayWithApplePayButtonPaymentAuthorizationPhase,
        provider: OnrampProvider,
        onWillBuy: () -> Void
    ) {
        switch phase {
        case .willAuthorize:
            onWillBuy()

        case .didAuthorize(let payment, let resultHandler):
            let applePayResult = OnrampApplePayUtils.mapPaymentResult(payment)
            let authorization = ApplePayAuthorizationResult(
                provider: provider,
                applePayResult: applePayResult,
                resultHandler: resultHandler
            )
            guard let authorizationHandler else {
                authorization.fail()
                return
            }
            authorizationHandler.handleApplePayAuthorization(authorization)

        case .didFinish:
            break

        @unknown default:
            break
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
