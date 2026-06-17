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
        config: ApplePayProviderConfig
    ) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = config.merchantIdentifier
        request.supportedNetworks = [.visa, .masterCard]
        request.merchantCapabilities = [.threeDSecure, .credit, .debit]
        request.countryCode = config.countryCode
        request.currencyCode = currencyCode
        request.requiredBillingContactFields = [.postalAddress, .name]
        request.requiredShippingContactFields = [.emailAddress]
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: config.summaryItemLabel, amount: amount as NSDecimalNumber, type: .final),
        ]
        return request
    }

    static func mapPaymentResult(_ payment: PKPayment) throws -> OnrampApplePayResult {
        guard let email = payment.shippingContact?.emailAddress, !email.isEmpty else {
            throw PKPaymentRequest.paymentContactInvalidError(
                withContactField: .emailAddress,
                localizedDescription: nil
            )
        }

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
