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
    static func makePaymentRequest(amount: Decimal, currencyCode: String) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = OnrampApplePayConstants.merchantIdentifier
        request.supportedNetworks = [.visa, .masterCard]
        request.merchantCapabilities = .threeDSecure
        request.countryCode = Locale.current.region?.identifier ?? "US"
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
}
