//
//  OnrampNativePaymentRequestItem.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct OnrampNativePaymentRequestItem {
    public let quotesItem: OnrampQuotesRequestItem
    public let redirectSettings: OnrampRedirectSettings
    public let paymentToken: String
    public let quoteId: String
    public let userData: UserData

    public init(
        quotesItem: OnrampQuotesRequestItem,
        redirectSettings: OnrampRedirectSettings,
        paymentToken: String,
        quoteId: String,
        userData: UserData
    ) {
        self.quotesItem = quotesItem
        self.redirectSettings = redirectSettings
        self.paymentToken = paymentToken
        self.quoteId = quoteId
        self.userData = userData
    }
}

public extension OnrampNativePaymentRequestItem {
    struct UserData {
        public let email: String?
        public let firstName: String?
        public let lastName: String?
        public let billingAddress: BillingAddress?

        public init(email: String?, firstName: String?, lastName: String?, billingAddress: BillingAddress?) {
            self.email = email
            self.firstName = firstName
            self.lastName = lastName
            self.billingAddress = billingAddress
        }
    }

    struct BillingAddress {
        public let street: String?
        public let city: String?
        public let subAdministrativeArea: String?
        public let state: String?
        public let postalCode: String?
        public let country: String?
        public let isoCountryCode: String?

        public init(
            street: String?,
            city: String?,
            subAdministrativeArea: String?,
            state: String?,
            postalCode: String?,
            country: String?,
            isoCountryCode: String?
        ) {
            self.street = street
            self.city = city
            self.subAdministrativeArea = subAdministrativeArea
            self.state = state
            self.postalCode = postalCode
            self.country = country
            self.isoCountryCode = isoCountryCode
        }
    }
}
