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
        #expect(Set(request.requiredBillingContactFields) == Set([.postalAddress, .name, .emailAddress]))
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

    @Test("mapPaymentResult base64-encodes the payment token and forwards billing contact fields")
    func mapPaymentResultMapping() throws {
        let tokenBytes = Data([0xDE, 0xAD, 0xBE, 0xEF])
        let payment = StubPKPayment(
            tokenData: tokenBytes,
            email: "user@example.com",
            firstName: "Ada",
            lastName: "Lovelace",
            postalAddress: PostalAddress(
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

    @Test("mapPaymentResult returns nil when billing contact has no email")
    func mapPaymentResultNoEmail() {
        let payment = StubPKPayment(tokenData: Data())

        #expect(OnrampApplePayUtils.mapPaymentResult(payment) == nil)
    }

    @Test("mapPaymentResult returns nil when email is empty")
    func mapPaymentResultEmptyEmail() {
        let payment = StubPKPayment(tokenData: Data(), email: "")

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

    init(
        tokenData: Data,
        email: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        postalAddress: PostalAddress? = nil
    ) {
        _token = StubPKPaymentToken(paymentData: tokenData)

        if email == nil, firstName == nil, lastName == nil, postalAddress == nil {
            _billingContact = nil
        } else {
            let contact = PKContact()
            contact.emailAddress = email
            if let firstName = firstName, let lastName = lastName {
                var components = PersonNameComponents()
                components.givenName = firstName
                components.familyName = lastName
                contact.name = components
            }
            if let address = postalAddress {
                let postal = CNMutablePostalAddress()
                postal.city = address.city
                postal.state = address.state
                postal.postalCode = address.postalCode
                postal.country = address.country
                contact.postalAddress = postal
            }
            _billingContact = contact
        }

        super.init()
    }

    override var token: PKPaymentToken { _token }
    override var billingContact: PKContact? { _billingContact }
}
