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
    let tokenItem: TokenItem
    let countryCode: String
    weak var amountInput: OnrampAmountInput?
    weak var authorizationHandler: ApplePayButtonPaymentAuthorizationHandler?

    private let balanceFormatter = BalanceFormatter()

    init(
        geoEligibilityService: GeoEligibilityService,
        tokenItem: TokenItem,
        amountInput: OnrampAmountInput?,
        authorizationHandler: ApplePayButtonPaymentAuthorizationHandler?,
        countryCode: String = Locale.current.region?.identifier ?? "US"
    ) {
        self.geoEligibilityService = geoEligibilityService
        self.tokenItem = tokenItem
        self.countryCode = countryCode
        self.amountInput = amountInput
        self.authorizationHandler = authorizationHandler
    }

    func make(
        provider: OnrampProvider,
        onWillBuy: @escaping () -> Void,
        onWidgetBuy: @escaping () -> Void
    ) -> OnrampOfferViewModel.BuyAction {
        return widget(onWillBuy: onWillBuy, onWidgetBuy: onWidgetBuy)

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
            authorizationHandler?.applePaySheetWillPresent()

        case .didAuthorize(let payment, let resultHandler):
            guard let applePayResult = OnrampApplePayUtils.mapPaymentResult(payment) else {
                let error = PKPaymentRequest.paymentContactInvalidError(
                    withContactField: .emailAddress,
                    localizedDescription: nil
                )
                resultHandler(.init(status: .failure, errors: [error]))
                return
            }
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
            authorizationHandler?.applePaySheetDidFinish()

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
