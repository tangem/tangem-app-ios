//
//  VisaCustomerInfoResponseSanitizedTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPay
@testable import Tangem

@Suite("VisaCustomerInfoResponse.sanitizedForDiskCache")
struct VisaCustomerInfoResponseSanitizedTests {
    // MARK: - Sensitive card fields are wiped

    @Test("card.token is stripped")
    func cardToken_isWiped() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated(cardToken: "secret-network-token")

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.card?.token == "")
    }

    @Test("card.embossName is stripped")
    func cardEmbossName_isWiped() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated(cardEmbossName: "JOHN DOE")

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.card?.embossName == "")
    }

    @Test("card.expirationMonth is stripped")
    func cardExpirationMonth_isWiped() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated(cardExpirationMonth: "11")

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.card?.expirationMonth == "")
    }

    @Test("card.expirationYear is stripped")
    func cardExpirationYear_isWiped() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated(cardExpirationYear: "2031")

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.card?.expirationYear == "")
    }

    @Test("card.isPinSet is reset to false")
    func cardIsPinSet_isReset() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated(cardIsPinSet: true)
        // sanity check: fixture really populates isPinSet=true
        #expect(response.card?.isPinSet == true)

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.card?.isPinSet == false)
    }

    @Test("kyc payload is dropped entirely")
    func kyc_isDropped() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated()
        // sanity check: fixture really has KYC data
        #expect(response.kyc != nil)

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.kyc == nil)
    }

    // MARK: - Display-relevant card fields are preserved

    @Test("card.cardNumberEnd is preserved (needed for '*5123' subtitle)")
    func cardNumberEnd_isPreserved() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated()

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.card?.cardNumberEnd == response.card?.cardNumberEnd)
    }

    @Test("card.cardType is preserved")
    func cardType_isPreserved() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated()

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.card?.cardType == response.card?.cardType)
    }

    @Test("card.cardStatus is preserved (needed for freezing state)")
    func cardStatus_isPreserved() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated()

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.card?.cardStatus == response.card?.cardStatus)
    }

    // MARK: - Top-level non-sensitive fields are preserved

    @Test("id is preserved")
    func id_isPreserved() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated()

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.id == response.id)
    }

    @Test("state is preserved")
    func state_isPreserved() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated()

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.state == response.state)
    }

    @Test("createdAt is preserved")
    func createdAt_isPreserved() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated()

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.createdAt == response.createdAt)
    }

    @Test("productInstance is preserved (needed to reconstruct TangemPayAccount)")
    func productInstance_isPreserved() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated()

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.productInstance?.id == response.productInstance?.id)
        #expect(sanitized.productInstance?.cardId == response.productInstance?.cardId)
        #expect(sanitized.productInstance?.status == response.productInstance?.status)
        #expect(sanitized.productInstance?.displayName == response.productInstance?.displayName)
    }

    @Test("paymentAccount is preserved (public blockchain addresses)")
    func paymentAccount_isPreserved() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated()

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.paymentAccount?.id == response.paymentAccount?.id)
        #expect(sanitized.paymentAccount?.customerWalletAddress == response.paymentAccount?.customerWalletAddress)
        #expect(sanitized.paymentAccount?.address == response.paymentAccount?.address)
    }

    @Test("depositAddress is preserved (public blockchain address)")
    func depositAddress_isPreserved() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated()

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.depositAddress == response.depositAddress)
    }

    // MARK: - Edge cases

    @Test("nil card stays nil after sanitization")
    func nilCard_staysNil() throws {
        let response = try VisaCustomerInfoResponseFixture.minimal()

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.card == nil)
    }

    @Test("encoded sanitized JSON does not contain the original card token")
    func encodedSanitized_doesNotLeakCardToken() throws {
        let secret = "uniquesecrettokenvalue"
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated(cardToken: secret)

        let sanitized = response.sanitizedForDiskCache()
        let data = try VisaCustomerInfoResponseFixture.makeEncoder().encode(sanitized)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(!json.contains(secret), "Sanitized JSON must not contain the original card token")
    }

    @Test("encoded sanitized JSON does not contain the original emboss name")
    func encodedSanitized_doesNotLeakEmbossName() throws {
        let unique = "VERYUNIQUEEMBOSSNAME"
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated(cardEmbossName: unique)

        let sanitized = response.sanitizedForDiskCache()
        let data = try VisaCustomerInfoResponseFixture.makeEncoder().encode(sanitized)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(!json.contains(unique), "Sanitized JSON must not contain the original emboss name")
    }
}
