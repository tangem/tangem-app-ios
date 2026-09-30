//
//  TangemPayOfframpPreSignatureVerifierTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import Testing
import TangemPay
@testable import Tangem

@Suite("TangemPay off-ramp pre-signature verification")
struct TangemPayOfframpPreSignatureVerifierTests {
    private typealias Verifier = TangemPayOfframpPreSignatureVerifier

    private static let recipient = "0x059dbd5f24a000d28f83268db1c85c9c3ab6a123"
    private static let asset = "0x833589fcD6eDb6E08f4c7C32D4f71b54bdA02913"

    private let verifier = Verifier(fiatItem: TangemPayUtilities.fiatItem)

    @Test("an order matching the entered amount, network and asset verifies")
    func verificationAcceptsMatchingOrder() throws {
        let preSignature = try makePreSignature(amount: "8460000", chainId: 8453)

        try verifier.verify(preSignature, against: makeExpectation())
    }

    @Test("an order moving another amount is rejected")
    func verificationRejectsAmountMismatch() throws {
        let preSignature = try makePreSignature(amount: "846000000", chainId: 8453)

        #expect(throws: Verifier.Error.amountMismatch) {
            try verifier.verify(preSignature, against: makeExpectation())
        }
    }

    @Test("an order bound to another network is rejected")
    func verificationRejectsNetworkMismatch() throws {
        let preSignature = try makePreSignature(amount: "8460000", chainId: 137)

        #expect(throws: Verifier.Error.networkMismatch) {
            try verifier.verify(preSignature, against: makeExpectation())
        }
    }

    @Test("an order whose hash does not match its structured data is rejected")
    func verificationRejectsHashMismatch() throws {
        let preSignature = try makePreSignature(amount: "8460000", chainId: 8453, hash: Data(repeating: 0, count: 32))

        #expect(throws: Verifier.Error.hashMismatch) {
            try verifier.verify(preSignature, against: makeExpectation())
        }
    }

    // MARK: - Helpers

    private func makeExpectation() -> Verifier.Expectation {
        Verifier.Expectation(amountInCents: 846, chainId: 8453, tokenContractAddress: Self.asset.lowercased())
    }

    private func makePreSignature(
        amount: String,
        chainId: Int,
        hash: Data? = nil
    ) throws -> TangemPayWithdrawPreSignature {
        let json = """
        {
          "types": {
            "EIP712Domain": [
              { "name": "name", "type": "string" },
              { "name": "chainId", "type": "uint256" }
            ],
            "Withdraw": [
              { "name": "asset", "type": "address" },
              { "name": "recipient", "type": "address" },
              { "name": "amount", "type": "uint256" }
            ]
          },
          "primaryType": "Withdraw",
          "domain": {
            "name": "Collateral",
            "chainId": \(chainId)
          },
          "message": {
            "asset": "\(Self.asset)",
            "recipient": "\(Self.recipient)",
            "amount": \(amount)
          }
        }
        """

        let typedData = try JSONDecoder().decode(EIP712TypedData.self, from: Data(json.utf8))

        return TangemPayWithdrawPreSignature(
            sender: "0xabe0b741c5ca100a05d62532cbebdc8891932305",
            hash: hash ?? typedData.signHash,
            salt: Data(),
            structuredData: typedData
        )
    }
}
