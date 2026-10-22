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
    private static let foreignAsset = "0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2"
    private static let depositAddress = TangemPayWithdrawTypedDataFixture.collateral.lowercased()
    private static let foreignCollateral = "0xca4cae1f7240390c035877b56532a2ec59fa0d7c"

    private let verifier = Verifier(fiatItem: TangemPayUtilities.fiatItem)

    @Test("an order matching the entered amount, network and asset verifies")
    func verificationAcceptsMatchingOrder() throws {
        let preSignature = try makePreSignature(amount: "8460000", chainId: 8453)

        try verifier.verify(preSignature, against: makeExpectation(), depositAddress: Self.depositAddress)
    }

    @Test("an order moving another amount is rejected")
    func verificationRejectsAmountMismatch() throws {
        let preSignature = try makePreSignature(amount: "846000000", chainId: 8453)

        #expect(throws: Verifier.Error.amountMismatch) {
            try verifier.verify(preSignature, against: makeExpectation(), depositAddress: Self.depositAddress)
        }
    }

    @Test("an order bound to another network is rejected")
    func verificationRejectsNetworkMismatch() throws {
        let preSignature = try makePreSignature(amount: "8460000", chainId: 137)

        #expect(throws: Verifier.Error.networkMismatch) {
            try verifier.verify(preSignature, against: makeExpectation(), depositAddress: Self.depositAddress)
        }
    }

    @Test("an order moving another token is rejected")
    func verificationRejectsAssetMismatch() throws {
        var fixture = makeFixture(amount: "8460000", chainId: 8453)
        fixture.asset = Self.foreignAsset

        let preSignature = try fixture.makePreSignature()

        #expect(throws: Verifier.Error.networkMismatch) {
            try verifier.verify(preSignature, against: makeExpectation(), depositAddress: Self.depositAddress)
        }
    }

    @Test("an order bound to another collateral contract is rejected")
    func verificationRejectsContractMismatch() throws {
        var fixture = makeFixture(amount: "8460000", chainId: 8453)
        fixture.verifyingContract = Self.foreignCollateral

        let preSignature = try fixture.makePreSignature()

        #expect(throws: Verifier.Error.networkMismatch) {
            try verifier.verify(preSignature, against: makeExpectation(), depositAddress: Self.depositAddress)
        }
    }

    @Test("an order whose typed data is not the collateral Withdraw is rejected")
    func verificationRejectsSchemaMismatch() throws {
        var fixture = makeFixture(amount: "8460000", chainId: 8453)
        fixture.primaryType = "AddAdmin"

        let preSignature = try fixture.makePreSignature()

        #expect(throws: Verifier.Error.schemaMismatch) {
            try verifier.verify(preSignature, against: makeExpectation(), depositAddress: Self.depositAddress)
        }
    }

    @Test("an order whose hash does not match its structured data is rejected")
    func verificationRejectsHashMismatch() throws {
        let preSignature = try makePreSignature(amount: "8460000", chainId: 8453, hash: Data(repeating: 0, count: 32))

        #expect(throws: Verifier.Error.hashMismatch) {
            try verifier.verify(preSignature, against: makeExpectation(), depositAddress: Self.depositAddress)
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
        var fixture = makeFixture(amount: amount, chainId: chainId)
        fixture.hash = hash

        return try fixture.makePreSignature()
    }

    private func makeFixture(amount: String, chainId: Int) -> TangemPayWithdrawTypedDataFixture {
        TangemPayWithdrawTypedDataFixture(
            chainId: chainId,
            asset: Self.asset,
            recipient: Self.recipient,
            amount: amount
        )
    }
}
