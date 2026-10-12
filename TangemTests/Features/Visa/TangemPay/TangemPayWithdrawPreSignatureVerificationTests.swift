//
//  TangemPayWithdrawPreSignatureVerificationTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import Testing
import TangemPay
@testable import Tangem

@Suite("TangemPay withdraw pre-signature verification")
struct TangemPayWithdrawPreSignatureVerificationTests {
    private static let recipient = "0x059dbd5f24a000d28f83268db1c85c9c3ab6a123"
    /// Base USDC and Base USDT: the EIP-712 `address` type only encodes a real 20-byte address,
    /// so a made-up one would drop out of `signHash` instead of binding it to the token.
    private static let asset = "0x833589fcD6eDb6E08f4c7C32D4f71b54bdA02913"
    private static let foreignAsset = "0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2"

    @Test("the message amount is scaled by the account's stable decimals")
    func verificationUsesStableDecimals() throws {
        // 846 cents = $8.46; a six-decimal stable puts 8.46 * 10^6 into the message.
        let preSignature = try makePreSignature(amount: "8460000", chainId: 8453)

        try CommonTangemPayWithdrawTransactionService.verifyPreSignature(
            preSignature,
            against: makeRequest(target: makeTarget()),
            fiatItem: TangemPayUtilities.fiatItem
        )
    }

    @Test("an untargeted withdrawal claims no network — whatever the BFF's default is, it verifies")
    func verificationSkipsNetworkCheckWhenUntargeted() throws {
        let preSignature = try makePreSignature(amount: "8460000", chainId: 84532)

        try CommonTangemPayWithdrawTransactionService.verifyPreSignature(
            preSignature,
            against: makeRequest(target: nil),
            fiatItem: TangemPayUtilities.fiatItem
        )
    }

    @Test("an amount scaled by the wrong decimals is rejected")
    func verificationRejectsWrongScale() throws {
        let preSignature = try makePreSignature(amount: "846000000", chainId: 8453)

        #expect(throws: (any Error).self) {
            try CommonTangemPayWithdrawTransactionService.verifyPreSignature(
                preSignature,
                against: makeRequest(target: makeTarget()),
                fiatItem: TangemPayUtilities.fiatItem
            )
        }
    }

    @Test("a signature bound to another network is rejected")
    func verificationRejectsForeignChain() throws {
        let preSignature = try makePreSignature(amount: "8460000", chainId: 137)

        #expect(throws: (any Error).self) {
            try CommonTangemPayWithdrawTransactionService.verifyPreSignature(
                preSignature,
                against: makeRequest(target: makeTarget()),
                fiatItem: TangemPayUtilities.fiatItem
            )
        }
    }

    @Test("a signature bound to another token is rejected")
    func verificationRejectsForeignAsset() throws {
        let preSignature = try makePreSignature(amount: "8460000", chainId: 8453, asset: Self.foreignAsset)

        #expect(throws: (any Error).self) {
            try CommonTangemPayWithdrawTransactionService.verifyPreSignature(
                preSignature,
                against: makeRequest(target: makeTarget()),
                fiatItem: TangemPayUtilities.fiatItem
            )
        }
    }

    @Test("the chain id survives being quoted as a string")
    func verificationAcceptsStringChainId() throws {
        let preSignature = try makePreSignature(amount: "8460000", chainId: 8453, quotesChainId: true)

        try CommonTangemPayWithdrawTransactionService.verifyPreSignature(
            preSignature,
            against: makeRequest(target: makeTarget()),
            fiatItem: TangemPayUtilities.fiatItem
        )
    }

    @Test("a BNB Smart Chain withdrawal is scaled by eighteen decimals — its stables are Binance-Peg")
    func verificationUsesBSCDecimals() throws {
        let bscChainId = 56
        // 8.46 * 10^18, the largest scale that still fits the Int the message amount is read as.
        let preSignature = try makePreSignature(amount: "8460000000000000000", chainId: bscChainId)

        try CommonTangemPayWithdrawTransactionService.verifyPreSignature(
            preSignature,
            against: makeRequest(target: makeTarget(chainId: bscChainId)),
            fiatItem: TangemPayUtilities.fiatItem
        )
    }

    @Test("the message amount survives being quoted as a string")
    func verificationAcceptsStringAmount() throws {
        let preSignature = try makePreSignature(amount: "\"8460000\"", chainId: 8453)

        try CommonTangemPayWithdrawTransactionService.verifyPreSignature(
            preSignature,
            against: makeRequest(target: makeTarget()),
            fiatItem: TangemPayUtilities.fiatItem
        )
    }

    // MARK: - Helpers

    private func makeTarget(chainId: Int = 8453) -> TangemPayWithdrawTarget {
        TangemPayWithdrawTarget(
            chainId: chainId,
            // The BFF echoes contract addresses in an arbitrary checksum casing.
            tokenContractAddress: Self.asset.lowercased()
        )
    }

    private func makeRequest(target: TangemPayWithdrawTarget?) -> TangemPayWithdrawRequest {
        TangemPayWithdrawRequest(
            amountInCents: "846",
            destination: Self.recipient,
            target: target
        )
    }

    /// `amount` goes into the JSON verbatim, so a test can quote it the way the BFF would.
    private func makePreSignature(
        amount: String,
        chainId: Int,
        asset: String = TangemPayWithdrawPreSignatureVerificationTests.asset,
        quotesChainId: Bool = false
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
            "chainId": \(quotesChainId ? "\"\(chainId)\"" : "\(chainId)")
          },
          "message": {
            "asset": "\(asset)",
            "recipient": "\(Self.recipient)",
            "amount": \(amount)
          }
        }
        """

        let typedData = try JSONDecoder().decode(EIP712TypedData.self, from: Data(json.utf8))

        return TangemPayWithdrawPreSignature(
            sender: "0xabe0b741c5ca100a05d62532cbebdc8891932305",
            hash: typedData.signHash,
            salt: Data(),
            structuredData: typedData
        )
    }
}
