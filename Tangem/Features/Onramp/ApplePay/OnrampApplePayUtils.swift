//
//  OnrampApplePayUtils.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import PassKit
import TangemExpress

enum OnrampApplePayUtils {
    static func makePaymentRequest(
        amount: Decimal,
        currencyCode: String,
        countryCode: String,
        summaryItemLabel: String,
        merchantIdentifier: String
    ) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = merchantIdentifier
        request.supportedNetworks = [.visa, .masterCard]
        request.merchantCapabilities = .threeDSecure
        request.countryCode = countryCode
        request.currencyCode = currencyCode
        request.requiredBillingContactFields = [.postalAddress, .name, .emailAddress]
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: summaryItemLabel, amount: amount as NSDecimalNumber),
        ]
        return request
    }

    static func mapPaymentResult(_ payment: PKPayment) -> OnrampApplePayResult? {
        let email = payment.billingContact?.emailAddress ?? "dfedorov@tangem.com"

        let tokenString = payment.token.paymentData.base64EncodedString()

        let billingAddress: OnrampNativePaymentRequestItem.BillingAddress? = payment.billingContact?.postalAddress.map { address in
            OnrampNativePaymentRequestItem.BillingAddress(
                city: address.city,
                state: address.state,
                postalCode: address.postalCode,
                country: address.country
            )
        }

        let userData = OnrampNativePaymentRequestItem.UserData(
            email: email,
            firstName: payment.billingContact?.name?.givenName,
            lastName: payment.billingContact?.name?.familyName,
            billingAddress: billingAddress
        )

        return OnrampApplePayResult(paymentToken: tokenString, userData: userData)
    }
}
