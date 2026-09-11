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

    @Test("cards[].token is stripped")
    func cardToken_isWiped() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated(cardToken: "secret-network-token")

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.cards.first?.token == "")
    }

    @Test("cards[].embossName is stripped")
    func cardEmbossName_isWiped() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated(cardEmbossName: "JOHN DOE")

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.cards.first?.embossName == "")
    }

    @Test("cards[].expirationMonth is stripped")
    func cardExpirationMonth_isWiped() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated(cardExpirationMonth: "11")

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.cards.first?.expirationMonth == "")
    }

    @Test("cards[].expirationYear is stripped")
    func cardExpirationYear_isWiped() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated(cardExpirationYear: "2031")

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.cards.first?.expirationYear == "")
    }

    @Test("cards[].isPinSet is preserved")
    func cardIsPinSet_isPreserved() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated(cardIsPinSet: true)
        // sanity check: fixture really populates isPinSet=true
        #expect(response.cards.first?.isPinSet == true)

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.cards.first?.isPinSet == true)
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

    @Test("cards[].cardNumberEnd is preserved (needed for '*5123' subtitle)")
    func cardNumberEnd_isPreserved() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated()

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.cards.first?.cardNumberEnd == response.cards.first?.cardNumberEnd)
    }

    @Test("cards[].cardType is preserved")
    func cardType_isPreserved() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated()

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.cards.first?.cardType == response.cards.first?.cardType)
    }

    @Test("cards[].cardStatus is preserved (needed for freezing state)")
    func cardStatus_isPreserved() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated()

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.cards.first?.cardStatus == response.cards.first?.cardStatus)
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

    @Test("productInstances are preserved (needed to reconstruct TangemPayAccount)")
    func productInstances_arePreserved() throws {
        let response = try VisaCustomerInfoResponseFixture.fullyPopulated()

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.productInstances.count == response.productInstances.count)
        #expect(sanitized.productInstances.first?.id == response.productInstances.first?.id)
        #expect(sanitized.productInstances.first?.cardId == response.productInstances.first?.cardId)
        #expect(sanitized.productInstances.first?.status == response.productInstances.first?.status)
        #expect(sanitized.productInstances.first?.displayName == response.productInstances.first?.displayName)
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

    @Test("empty cards stay empty after sanitization")
    func emptyCards_stayEmpty() throws {
        let response = try VisaCustomerInfoResponseFixture.minimal()

        let sanitized = response.sanitizedForDiskCache()

        #expect(sanitized.cards.isEmpty)
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
