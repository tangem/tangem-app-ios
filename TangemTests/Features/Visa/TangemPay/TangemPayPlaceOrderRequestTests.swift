//
//  TangemPayPlaceOrderRequestTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPay

@Suite("TangemPayPlaceOrderRequest encoding")
struct TangemPayPlaceOrderRequestTests {
    /// Mirrors the encoder used by `CommonCustomerInfoManagementService` for `POST /order`.
    private func encodeToDictionary(_ request: TangemPayPlaceOrderRequest) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(request)
        let object = try JSONSerialization.jsonObject(with: data)
        return try #require(object as? [String: Any])
    }

    @Test("Virtual Account order body is exactly { data: { type, specification_name, deposit_address } }")
    func virtualAccountOrder_encodesExactBody() throws {
        let depositAddress = "0xCOLLATERAL"

        let json = try encodeToDictionary(.init(depositAddress: depositAddress))

        // Only `data` at the root — no `wallet_address`.
        #expect(Set(json.keys) == ["data"])

        let data = try #require(json["data"] as? [String: Any])
        #expect(data["type"] as? String == "ACCOUNT_ISSUE_VIRTUAL_RAIN")
        #expect(data["specification_name"] as? String == "SP_000006")
        #expect(data["deposit_address"] as? String == depositAddress)

        // Exactly these three keys — no customer_wallet_address / payment_account_address.
        #expect(Set(data.keys) == ["type", "specification_name", "deposit_address"])
    }

    @Test("Card issue order body is unchanged: customer_wallet_address present, no deposit_address")
    func cardIssueOrder_encodesLegacyBody() throws {
        let json = try encodeToDictionary(
            .init(type: "CARD_ISSUE_VIRTUAL_RAIN", customerWalletAddress: "0xWALLET", specificationName: "SP_000004")
        )

        #expect(Set(json.keys) == ["data"])

        let data = try #require(json["data"] as? [String: Any])
        #expect(data["type"] as? String == "CARD_ISSUE_VIRTUAL_RAIN")
        #expect(data["specification_name"] as? String == "SP_000004")
        #expect(data["customer_wallet_address"] as? String == "0xWALLET")
        #expect(data["deposit_address"] == nil)
        #expect(Set(data.keys) == ["type", "specification_name", "customer_wallet_address"])
    }

    @Test("Campaign card issue order body carries deeplink_value alongside the legacy fields")
    func campaignCardIssueOrder_encodesDeeplinkValue() throws {
        let deeplinkValue = "tpay_for_harvard123"

        let json = try encodeToDictionary(
            .init(
                type: "CARD_ISSUE_VIRTUAL_RAIN",
                customerWalletAddress: "0xWALLET",
                specificationName: "SP_000004",
                deeplinkValue: deeplinkValue
            )
        )

        #expect(Set(json.keys) == ["data"])

        let data = try #require(json["data"] as? [String: Any])
        #expect(data["type"] as? String == "CARD_ISSUE_VIRTUAL_RAIN")
        #expect(data["specification_name"] as? String == "SP_000004")
        #expect(data["customer_wallet_address"] as? String == "0xWALLET")
        #expect(data["deeplink_value"] as? String == deeplinkValue)

        #expect(
            Set(data.keys) == [
                "type",
                "specification_name",
                "customer_wallet_address",
                "deeplink_value",
            ]
        )
    }

    @Test("Bank off-ramp Mode A body carries bank_account_id and nothing else")
    func bankOfframpModeA_encodesExactBody() throws {
        let json = try encodeToDictionary(
            .init(
                offrampAmountInCents: 10000,
                chainId: 137,
                tokenContractAddress: "0xUSDC",
                bankAccountId: "7b0f7d70"
            )
        )

        let data = try #require(json["data"] as? [String: Any])
        #expect(data["type"] as? String == "BANK_OFFRAMP_RAIN")
        #expect(data["amount_in_cents"] as? Int == 10000)
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

    @Test("Bank off-ramp Mode B body carries bank_account and no bank_account_id")
    func bankOfframpModeB_encodesExactBody() throws {
        let address = TangemPayPlaceOrderRequest.BankAccount.Address(
            line1: "123 Main St",
            line2: nil,
            city: "New York",
            region: "NY",
            postalCode: "10001",
            countryCode: "US"
        )

        let json = try encodeToDictionary(
            .init(
                offrampAmountInCents: 10000,
                chainId: 137,
                tokenContractAddress: "0xUSDC",
                bankAccount: .init(
                    displayName: nil,
                    details: .init(
                        currency: "USD",
                        rail: .wire,
                        thirdParty: false,
                        beneficiary: .individual(firstName: "John", lastName: "Doe"),
                        beneficiaryAddress: address,
                        bankName: "Chase Bank",
                        bankAddress: address,
                        accountNumber: "1234567890",
                        routingNumber: "021000021",
                        bankAccountType: .savings
                    )
                )
            )
        )

        let data = try #require(json["data"] as? [String: Any])
        #expect(data["bank_account_id"] == nil)
        #expect(
            Set(data.keys) == [
                "type",
                "amount_in_cents",
                "chain_id",
                "token_contract_address",
                "bank_account",
            ]
        )

        let details = try #require(
            (data["bank_account"] as? [String: Any])?["details"] as? [String: Any]
        )
        #expect(details["rail"] as? String == "WIRE")
        #expect(details["bank_account_type"] as? String == "SAVINGS")
        #expect(details["third_party"] as? Bool == false)
    }

    @Test("Plastic reissue order body carries source_product_instance_id alongside emboss_name and shipping_address")
    func plasticReissueOrder_encodesExactBody() throws {
        let shippingAddress = TangemPayPlaceOrderRequest.ShippingAddress(
            firstName: "John",
            lastName: "Doe",
            line1: "1 Main St",
            line2: nil,
            city: "New York",
            region: "NY",
            postalCode: "10001",
            phoneNumber: "+15551234567"
        )

        let json = try encodeToDictionary(
            .init(
                customerWalletAddress: "0xWALLET",
                sourceProductInstanceId: "pi-123",
                embossName: "JOHN DOE",
                shippingAddress: shippingAddress
            )
        )

        let data = try #require(json["data"] as? [String: Any])
        #expect(data["type"] as? String == "CARD_REISSUE_PLASTIC_RAIN")
        #expect(data["customer_wallet_address"] as? String == "0xWALLET")
        #expect(data["source_product_instance_id"] as? String == "pi-123")
        #expect(data["emboss_name"] as? String == "JOHN DOE")
        #expect(data["shipping_address"] != nil)
    }
}
