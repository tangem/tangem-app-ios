//
//  OnrampApplePayUtils.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import PassKit
import SwiftUI
import TangemExpress

enum OnrampApplePayUtils {
    static func makeBuyAction(
        provider: OnrampProvider,
        currencyCode: String?,
        countryCode: String,
        isApplePayAllowed: Bool,
        additionalAnalytics: @escaping () -> Void,
        onAuthorize: @escaping (OnrampProvider, OnrampApplePayResult, @escaping (PKPaymentAuthorizationResult) -> Void) -> Void,
        onFallbackBuy: @escaping () -> Void
    ) -> OnrampOfferViewModel.BuyAction {
        if isApplePayAllowed,
           provider.paymentMethod.type == .applePay,
           let quote = provider.quote,
           quote.nativePaymentAvailable == true,
           quote.quoteId != nil,
           let amount = provider.amount,
           let currencyCode {
            let request = makePaymentRequest(amount: amount, currencyCode: currencyCode, countryCode: countryCode)
            return .nativeApplePay(request: request) { phase in
                handlePhase(
                    phase,
                    provider: provider,
                    additionalAnalytics: additionalAnalytics,
                    onAuthorize: onAuthorize
                )
            }
        }

        return .button {
            additionalAnalytics()
            onFallbackBuy()
        }
    }

    static func makePaymentRequest(amount: Decimal, currencyCode: String, countryCode: String) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = OnrampApplePayConstants.merchantIdentifier
        request.supportedNetworks = [.visa, .masterCard]
        request.merchantCapabilities = .threeDSecure
        request.countryCode = countryCode
        request.currencyCode = currencyCode
        request.requiredBillingContactFields = [.postalAddress, .name, .emailAddress]
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Tangem", amount: amount as NSDecimalNumber),
        ]
        return request
    }

    static func mapPaymentResult(_ payment: PKPayment) -> OnrampApplePayResult {
        let tokenString = payment.token.paymentData.base64EncodedString()

        let billingAddress: OnrampNativePaymentRequestItem.BillingAddress? = payment.billingContact?.postalAddress.map { address in
            OnrampNativePaymentRequestItem.BillingAddress(
                street: address.street,
                city: address.city,
                subAdministrativeArea: address.subAdministrativeArea,
                state: address.state,
                postalCode: address.postalCode,
                country: address.country,
                isoCountryCode: address.isoCountryCode
            )
        }

        let userData = OnrampNativePaymentRequestItem.UserData(
            email: payment.billingContact?.emailAddress,
            firstName: payment.billingContact?.name?.givenName,
            lastName: payment.billingContact?.name?.familyName,
            billingAddress: billingAddress
        )

        return OnrampApplePayResult(paymentToken: tokenString, userData: userData)
    }

    // MARK: - Private

    private static func handlePhase(
        _ phase: PayWithApplePayButtonPaymentAuthorizationPhase,
        provider: OnrampProvider,
        additionalAnalytics: () -> Void,
        onAuthorize: (OnrampProvider, OnrampApplePayResult, @escaping (PKPaymentAuthorizationResult) -> Void) -> Void
    ) {
        switch phase {
        case .willAuthorize:
            additionalAnalytics()

        case .didAuthorize(let payment, let resultHandler):
            let applePayResult = mapPaymentResult(payment)
            onAuthorize(provider, applePayResult, resultHandler)

        case .didFinish:
            break

        @unknown default:
            break
        }
    }
}
