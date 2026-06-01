//
//  OnrampApplePayUtilsTests.swift
//  TangemTests
//
//  Created on 28.04.2026.
//

import Contacts
import Foundation
import PassKit
import Testing
@testable import Tangem
@testable import TangemExpress

@Suite("OnrampApplePayUtils")
struct OnrampApplePayUtilsTests {
    @Test("makePaymentRequest sets the merchant, networks, capabilities, currency, and country")
    func makePaymentRequestShape() throws {
        let amount = try #require(Decimal(string: "99.99"))
        let request = OnrampApplePayUtils.makePaymentRequest(
            amount: amount,
            currencyCode: "EUR",
            countryCode: "DE",
            summaryItemLabel: "1 ETH",
            merchantIdentifier: "merchant.example.tangem"
        )

        #expect(request.merchantIdentifier == "merchant.example.tangem")
        #expect(request.supportedNetworks == [.visa, .masterCard])
        #expect(request.merchantCapabilities == .threeDSecure)
        #expect(request.currencyCode == "EUR")
        #expect(request.countryCode == "DE")
        #expect(Set(request.requiredBillingContactFields) == Set([.postalAddress, .name]))
        #expect(Set(request.requiredShippingContactFields) == Set([.emailAddress]))
    }

    @Test("makePaymentRequest exposes a single summary item with the supplied label and amount")
    func makePaymentRequestSummaryItem() throws {
        let amount = try #require(Decimal(string: "12.50"))
        let request = OnrampApplePayUtils.makePaymentRequest(
            amount: amount,
            currencyCode: "USD",
            countryCode: "US",
            summaryItemLabel: "0.005 ETH",
            merchantIdentifier: "merchant.example.tangem"
        )

        #expect(request.paymentSummaryItems.count == 1)
        #expect(request.paymentSummaryItems.first?.label == "0.005 ETH")
        #expect(request.paymentSummaryItems.first?.amount == NSDecimalNumber(decimal: amount))
    }

    @Test("mapPaymentResult base64-encodes the payment token, reads email from shipping contact and forwards billing fields")
    func mapPaymentResultMapping() throws {
        let tokenBytes = Data([0xDE, 0xAD, 0xBE, 0xEF])
        let payment = StubPKPayment(
            tokenData: tokenBytes,
            shippingEmail: "user@example.com",
            billingFirstName: "Ada",
            billingLastName: "Lovelace",
            billingPostalAddress: PostalAddress(
                city: "Cupertino",
                state: "CA",
                postalCode: "95014",
                country: "United States"
            )
        )

        let result = try #require(OnrampApplePayUtils.mapPaymentResult(payment))

        #expect(result.paymentToken == tokenBytes.base64EncodedString())
        #expect(result.userData.email == "user@example.com")
        #expect(result.userData.firstName == "Ada")
        #expect(result.userData.lastName == "Lovelace")
        #expect(result.userData.billingAddress?.city == "Cupertino")
        #expect(result.userData.billingAddress?.state == "CA")
        #expect(result.userData.billingAddress?.postalCode == "95014")
        #expect(result.userData.billingAddress?.country == "United States")
    }

    @Test("mapPaymentResult returns nil when shipping contact has no email")
    func mapPaymentResultNoEmail() {
        let payment = StubPKPayment(tokenData: Data())

        #expect(OnrampApplePayUtils.mapPaymentResult(payment) == nil)
    }

    @Test("mapPaymentResult returns nil when shipping email is empty")
    func mapPaymentResultEmptyEmail() {
        let payment = StubPKPayment(tokenData: Data(), shippingEmail: "")

        #expect(OnrampApplePayUtils.mapPaymentResult(payment) == nil)
    }

    @Test("mapPaymentResult ignores email set on billing contact only")
    func mapPaymentResultIgnoresBillingEmail() {
        let payment = StubPKPayment(
            tokenData: Data(),
            billingEmail: "billing@example.com"
        )

        #expect(OnrampApplePayUtils.mapPaymentResult(payment) == nil)
    }
}

// MARK: - Stubs

private struct PostalAddress {
    let city: String
    let state: String
    let postalCode: String
    let country: String
}

private final class StubPKPaymentToken: PKPaymentToken {
    private let _paymentData: Data

    init(paymentData: Data) {
        _paymentData = paymentData
        super.init()
    }

    override var paymentData: Data { _paymentData }
}

private final class StubPKPayment: PKPayment {
    private let _token: PKPaymentToken
    private let _billingContact: PKContact?
    private let _shippingContact: PKContact?

    init(
        tokenData: Data,
        shippingEmail: String? = nil,
        billingEmail: String? = nil,
        billingFirstName: String? = nil,
        billingLastName: String? = nil,
        billingPostalAddress: PostalAddress? = nil
    ) {
        _token = StubPKPaymentToken(paymentData: tokenData)

        if billingEmail == nil, billingFirstName == nil, billingLastName == nil, billingPostalAddress == nil {
            _billingContact = nil
        } else {
            let contact = PKContact()
            contact.emailAddress = billingEmail
            if let billingFirstName, let billingLastName {
                var components = PersonNameComponents()
                components.givenName = billingFirstName
                components.familyName = billingLastName
                contact.name = components
            }
            if let billingPostalAddress {
                let postal = CNMutablePostalAddress()
                postal.city = billingPostalAddress.city
                postal.state = billingPostalAddress.state
                postal.postalCode = billingPostalAddress.postalCode
                postal.country = billingPostalAddress.country
                contact.postalAddress = postal
            }
            _billingContact = contact
        }

        if let shippingEmail {
            let contact = PKContact()
            contact.emailAddress = shippingEmail
            _shippingContact = contact
        } else {
            _shippingContact = nil
        }

        super.init()
    }

    override var token: PKPaymentToken { _token }
    override var billingContact: PKContact? { _billingContact }
    override var shippingContact: PKContact? { _shippingContact }
}
