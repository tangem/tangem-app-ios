//
//  TangemPayOfframpOrderBuilderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPay
@testable import Tangem

@Suite("TangemPayOfframpOrderBuilder")
struct TangemPayOfframpOrderBuilderTests {
    @Test("Saved recipient builds a Mode A body with no rail and no bank account")
    func savedRecipient_buildsModeABody() throws {
        let builder = makeBuilder(recipient: .saved(bankAccountId: "pa-1"))
        builder.set(rail: .wire)

        let data = try dataObject(from: builder.buildOrderRequest())

        #expect(data["type"] as? String == "BANK_OFFRAMP_RAIN")
        #expect(data["amount_in_cents"] as? Int == 10000)
        #expect(data["chain_id"] as? Int == 137)
        #expect(data["token_contract_address"] as? String == Constants.tokenContractAddress)
        #expect(data["bank_account_id"] as? String == "pa-1")

        #expect(
            Set(data.keys) == [
                "type",
                "amount_in_cents",
                "chain_id",
                "token_contract_address",
                "bank_account_id",
            ]
        )
    }

    @Test("New individual builds a Mode B body carrying the Type of transfer choice")
    func newIndividual_buildsModeBBody() throws {
        let builder = makeBuilder(recipient: .newIndividual)
        builder.set(rail: .ach)
        builder.set(isThirdParty: true)
        builder.set(personalDetails: makePersonalDetails())
        builder.set(bankDetails: makeBankDetails())

        let data = try dataObject(from: builder.buildOrderRequest())
        let bankAccount = try #require(data["bank_account"] as? [String: Any])
        let details = try #require(bankAccount["details"] as? [String: Any])

        #expect(data["bank_account_id"] == nil)
        #expect(bankAccount["display_name"] == nil)

        #expect(details["currency"] as? String == "USD")
        #expect(details["rail"] as? String == "ACH")
        #expect(details["third_party"] as? Bool == true)
        #expect(details["account_number"] as? String == "1234567890")
        #expect(details["routing_number"] as? String == "021000021")
        #expect(details["bank_account_type"] as? String == "CHECKING")
        #expect(details["bank_name"] as? String == "Chase Bank")

        let beneficiary = try #require(details["beneficiary"] as? [String: Any])
        #expect(beneficiary["type"] as? String == "INDIVIDUAL")
        #expect(beneficiary["first_name"] as? String == "John")
        #expect(beneficiary["last_name"] as? String == "Doe")
        #expect(beneficiary["business_name"] == nil)
    }

    @Test("New business sends a business beneficiary and third_party true")
    func newBusiness_buildsBusinessBeneficiary() throws {
        let builder = makeBuilder(recipient: .newBusiness)
        builder.set(rail: .ach)
        builder.set(personalDetails: makePersonalDetails(name: .business(name: "Acme Inc")))
        builder.set(bankDetails: makeBankDetails())

        let data = try dataObject(from: builder.buildOrderRequest())
        let details = try #require(
            (data["bank_account"] as? [String: Any])?["details"] as? [String: Any]
        )
        let beneficiary = try #require(details["beneficiary"] as? [String: Any])

        #expect(details["third_party"] as? Bool == true)
        #expect(beneficiary["type"] as? String == "BUSINESS")
        #expect(beneficiary["business_name"] as? String == "Acme Inc")
        #expect(beneficiary["first_name"] == nil)
        #expect(beneficiary["last_name"] == nil)
    }

    @Test("The two detail halves land in their own addresses and are not crossed over")
    func detailHalves_mapToSeparateAddresses() throws {
        let builder = makeBuilder(recipient: .newBusiness)
        builder.set(rail: .ach)
        builder.set(bankDetails: makeBankDetails())
        builder.set(personalDetails: makePersonalDetails())

        let data = try dataObject(from: builder.buildOrderRequest())
        let details = try #require(
            (data["bank_account"] as? [String: Any])?["details"] as? [String: Any]
        )

        let beneficiaryAddress = try #require(details["beneficiary_address"] as? [String: Any])
        #expect(beneficiaryAddress["line1"] as? String == "123 Main St")
        #expect(beneficiaryAddress["city"] as? String == "New York")
        #expect(beneficiaryAddress["region"] as? String == "NY")
        #expect(beneficiaryAddress["postal_code"] as? String == "10001")
        #expect(beneficiaryAddress["country_code"] as? String == "US")
        #expect(beneficiaryAddress["line2"] == nil)

        let bankAddress = try #require(details["bank_address"] as? [String: Any])
        #expect(bankAddress["line1"] as? String == "270 Park Ave")
        #expect(bankAddress["region"] as? String == "NY")
        #expect(bankAddress["postal_code"] as? String == "10017")
        #expect(bankAddress["country_code"] as? String == "US")
        #expect(bankAddress["line2"] == nil)
    }

    @Test("A selected region is sent as its two-letter code, without the country prefix")
    func selectedRegion_stripsCountryPrefix() throws {
        let builder = makeBuilder(recipient: .newBusiness)
        builder.set(rail: .ach)
        builder.set(
            personalDetails: makePersonalDetails(
                region: TangemPayGeoRegion(code: "US-CA", name: "California", suggested: false),
                regionText: "California"
            )
        )
        builder.set(bankDetails: makeBankDetails())

        let data = try dataObject(from: builder.buildOrderRequest())
        let details = try #require(
            (data["bank_account"] as? [String: Any])?["details"] as? [String: Any]
        )
        let beneficiaryAddress = try #require(details["beneficiary_address"] as? [String: Any])

        #expect(beneficiaryAddress["region"] as? String == "CA")
    }

    @Test("A country without region selection sends the typed region text and its own country code")
    func unselectedRegion_sendsTypedText() throws {
        let builder = makeBuilder(recipient: .newBusiness)
        builder.set(rail: .ach)
        builder.set(
            personalDetails: makePersonalDetails(
                country: TangemPayGeoCountry(
                    code: "DE",
                    name: "Germany",
                    flagUrl: nil,
                    suggested: false,
                    hasRegions: false
                ),
                region: nil,
                regionText: "Bavaria"
            )
        )
        builder.set(bankDetails: makeBankDetails())

        let data = try dataObject(from: builder.buildOrderRequest())
        let details = try #require(
            (data["bank_account"] as? [String: Any])?["details"] as? [String: Any]
        )

        let beneficiaryAddress = try #require(details["beneficiary_address"] as? [String: Any])
        #expect(beneficiaryAddress["region"] as? String == "Bavaria")
        #expect(beneficiaryAddress["country_code"] as? String == "DE")

        let bankAddress = try #require(details["bank_address"] as? [String: Any])
        #expect(bankAddress["region"] as? String == "NY")
        #expect(bankAddress["country_code"] as? String == "US")
    }

    @Test(
        "Amount converts to whole cents, dropping any sub-cent fraction",
        arguments: [
            (Decimal(string: "18.023")!, 1802),
            (Decimal(string: "0.01")!, 1),
            (Decimal(string: "100")!, 10000),
            (Decimal(string: "0.009")!, 0),
        ]
    )
    func amount_convertsToWholeCents(amount: Decimal, expected: Int) throws {
        let builder = TangemPayOfframpOrderBuilder(recipient: .saved(bankAccountId: "pa-1"))
        builder.set(amount: amount)
        builder.set(token: makeToken())

        let data = try dataObject(from: builder.buildOrderRequest())

        #expect(data["amount_in_cents"] as? Int == expected)
    }

    @Test("Each missing input throws its own case")
    func missingInputs_throwMatchingErrors() throws {
        let noAmount = TangemPayOfframpOrderBuilder(recipient: .newIndividual)
        #expect(throws: TangemPayOfframpOrderBuilder.BuildError.missingAmount) {
            try noAmount.buildOrderRequest()
        }

        let noToken = TangemPayOfframpOrderBuilder(recipient: .newIndividual)
        noToken.set(amount: 100)
        #expect(throws: TangemPayOfframpOrderBuilder.BuildError.missingToken) {
            try noToken.buildOrderRequest()
        }

        let noTransferType = makeBuilder(recipient: .newIndividual)
        noTransferType.set(rail: .ach)
        #expect(throws: TangemPayOfframpOrderBuilder.BuildError.missingTransferType) {
            try noTransferType.buildOrderRequest()
        }

        let noRail = makeBuilder(recipient: .newBusiness)
        #expect(throws: TangemPayOfframpOrderBuilder.BuildError.missingRail) {
            try noRail.buildOrderRequest()
        }

        let noPersonalDetails = makeBuilder(recipient: .newBusiness)
        noPersonalDetails.set(rail: .ach)
        #expect(throws: TangemPayOfframpOrderBuilder.BuildError.missingPersonalDetails) {
            try noPersonalDetails.buildOrderRequest()
        }

        let noBankDetails = makeBuilder(recipient: .newBusiness)
        noBankDetails.set(rail: .ach)
        noBankDetails.set(personalDetails: makePersonalDetails())
        #expect(throws: TangemPayOfframpOrderBuilder.BuildError.missingBankDetails) {
            try noBankDetails.buildOrderRequest()
        }
    }

    @Test("Picking a saved account mid-flow discards the details already entered")
    func selectSaved_discardsEnteredDetails() throws {
        let builder = makeBuilder(recipient: .newIndividual)
        builder.set(rail: .ach)
        builder.set(isThirdParty: true)
        builder.set(personalDetails: makePersonalDetails())
        builder.set(bankDetails: makeBankDetails())

        builder.selectSaved(bankAccountId: "pa-2")

        #expect(builder.personalDetails == nil)
        #expect(builder.bankDetails == nil)
        #expect(builder.isThirdParty == nil)

        let data = try dataObject(from: builder.buildOrderRequest())

        #expect(data["bank_account_id"] as? String == "pa-2")
        #expect(data["bank_account"] == nil)
    }
}

// MARK: - Helpers

private extension TangemPayOfframpOrderBuilderTests {
    enum Constants {
        static let tokenContractAddress = "0x3c499c542cef5e3811e1192ce70d8cc03d5c3359"

        static let country = TangemPayGeoCountry(
            code: "US",
            name: "United States of America",
            flagUrl: nil,
            suggested: true,
            hasRegions: true
        )

        static let region = TangemPayGeoRegion(code: "US-NY", name: "New York", suggested: false)
    }

    func dataObject(from request: TangemPayPlaceOrderRequest) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let encoded = try encoder.encode(request)
        let object = try JSONSerialization.jsonObject(with: encoded)
        let root = try #require(object as? [String: Any])
        return try #require(root["data"] as? [String: Any])
    }

    func makeToken() -> TangemPayOfframpTokenSelection {
        TangemPayOfframpTokenSelection(
            chainId: 137,
            tokenContractAddress: Constants.tokenContractAddress
        )
    }

    func makeBuilder(recipient: TangemPayOfframpRecipient) -> TangemPayOfframpOrderBuilder {
        let builder = TangemPayOfframpOrderBuilder(recipient: recipient)
        builder.set(amount: 100)
        builder.set(token: makeToken())
        builder.set(accountType: .checking)
        return builder
    }

    func makePersonalDetails(
        name: TangemPayOfframpPersonalDetails.Name = .individual(firstName: "John", lastName: "Doe"),
        line2: String? = nil,
        country: TangemPayGeoCountry = Constants.country,
        region: TangemPayGeoRegion? = Constants.region,
        regionText: String = "New York"
    ) -> TangemPayOfframpPersonalDetails {
        TangemPayOfframpPersonalDetails(
            name: name,
            accountNumber: "1234567890",
            routingNumber: "021000021",
            line1: "123 Main St",
            line2: line2,
            city: "New York",
            country: country,
            region: region,
            regionText: regionText,
            postalCode: "10001"
        )
    }

    func makeBankDetails() -> TangemPayOfframpBankDetails {
        TangemPayOfframpBankDetails(
            name: "Chase Bank",
            line1: "270 Park Ave",
            city: "New York",
            region: Constants.region,
            postalCode: "10017"
        )
    }
}
