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
