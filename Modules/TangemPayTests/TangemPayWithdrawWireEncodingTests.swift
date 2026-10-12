//
//  TangemPayWithdrawWireEncodingTests.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPay

@Suite("TangemPayWithdraw wire encoding")
struct TangemPayWithdrawWireEncodingTests {
    @Test("A targeted signable-data request addresses the network and token explicitly")
    func signableDataRequestEncodesTarget() throws {
        let json = try encodeToDictionary(TangemPayWithdraw.SignableData.Request(makeRequest(target: Self.target)))

        #expect(json["chain_id"] as? Int == 8453)
        #expect(json["token_contract_address"] as? String == Self.tokenContractAddress)
        #expect(json["amount_in_cents"] as? String == "846")
        #expect(json["recipient_address"] as? String == Self.recipient)
        #expect(Set(json.keys) == ["amount_in_cents", "recipient_address", "chain_id", "token_contract_address"])
    }

    @Test("An untargeted signable-data request is byte-compatible with the pre-multichain body")
    func signableDataRequestOmitsEmptyTarget() throws {
        let json = try encodeToDictionary(TangemPayWithdraw.SignableData.Request(makeRequest(target: nil)))

        #expect(Set(json.keys) == ["amount_in_cents", "recipient_address"])
    }

    @Test("A targeted withdraw request carries the same addressing fields, plus the signature")
    func transactionRequestEncodesTarget() throws {
        let json = try encodeToDictionary(TangemPayWithdraw.Transaction.Request(
            makeRequest(target: Self.target),
            signature: makeSignature()
        ))

        #expect(json["chain_id"] as? Int == 8453)
        #expect(json["token_contract_address"] as? String == Self.tokenContractAddress)
        #expect(json["sender_address"] as? String == Self.sender)
        #expect(json["admin_signature"] as? String == "0xAABB")
        #expect(json["admin_salt"] as? String == "0xCCDD")
        #expect(Set(json.keys) == [
            "amount_in_cents", "sender_address", "recipient_address",
            "admin_signature", "admin_salt", "chain_id", "token_contract_address",
        ])
    }

    @Test("An untargeted withdraw request is byte-compatible with the pre-multichain body")
    func transactionRequestOmitsEmptyTarget() throws {
        let json = try encodeToDictionary(TangemPayWithdraw.Transaction.Request(
            makeRequest(target: nil),
            signature: makeSignature()
        ))

        #expect(Set(json.keys) == [
            "amount_in_cents", "sender_address", "recipient_address", "admin_signature", "admin_salt",
        ])
    }

    // MARK: - Helpers

    private static let recipient = "0x059dbd5f24a000d28f83268db1c85c9c3ab6a123"
    private static let sender = "0xabe0b741c5ca100a05d62532cbebdc8891932305"
    private static let tokenContractAddress = "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"

    private static let target = TangemPayWithdrawTarget(
        chainId: 8453,
        tokenContractAddress: tokenContractAddress
    )

    private func makeRequest(target: TangemPayWithdrawTarget?) -> TangemPayWithdrawRequest {
        TangemPayWithdrawRequest(amountInCents: "846", destination: Self.recipient, target: target)
    }

    private func makeSignature() -> TangemPayWithdrawSignature {
        TangemPayWithdrawSignature(
            sender: Self.sender,
            signature: Data([0xAA, 0xBB]),
            salt: Data([0xCC, 0xDD])
        )
    }

    /// Mirrors the encoder used by `CommonCustomerInfoManagementService` for the withdraw endpoints.
    private func encodeToDictionary<T: Encodable>(_ request: T) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(request)
        let object = try JSONSerialization.jsonObject(with: data)
        return try #require(object as? [String: Any])
    }
}
