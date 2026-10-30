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
    private typealias Service = CommonTangemPayWithdrawTransactionService

    private static let recipient = "0x059dbd5f24a000d28f83268db1c85c9c3ab6a123"
    /// Base USDC and Base USDT: the EIP-712 `address` type only encodes a real 20-byte address,
    /// so a made-up one would drop out of `signHash` instead of binding it to the token.
    private static let asset = "0x833589fcD6eDb6E08f4c7C32D4f71b54bdA02913"
    private static let foreignAsset = "0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2"
    private static let foreignCollateral = "0xca4cae1f7240390c035877b56532a2ec59fa0d7c"
    private static let baseDepositAddress = "0xbase"

    @Test("the message amount is scaled by the account's stable decimals")
    func verificationUsesStableDecimals() throws {
        // 846 cents = $8.46; a six-decimal stable puts 8.46 * 10^6 into the message.
        let preSignature = try makePreSignature(amount: "8460000", chainId: 8453)

        try verify(preSignature, target: makeTarget(), source: makeSource())
    }

    @Test("an untargeted withdrawal verifies on the account's default network")
    func verificationAcceptsUntargetedOnDefaultNetwork() throws {
        let preSignature = try makePreSignature(amount: "8460000", chainId: 8453)

        try verify(preSignature, target: nil, source: makeSource())
    }

    @Test("an untargeted withdrawal on a network other than the default is rejected")
    func verificationRejectsUntargetedOnForeignNetwork() throws {
        let preSignature = try makePreSignature(amount: "8460000", chainId: 84532)

        #expect(throws: (any Error).self) {
            try verify(preSignature, target: nil, source: makeSource())
        }
    }

    @Test("an amount scaled by the wrong decimals is rejected")
    func verificationRejectsWrongScale() throws {
        let preSignature = try makePreSignature(amount: "846000000", chainId: 8453)

        #expect(throws: (any Error).self) {
            try verify(preSignature, target: makeTarget(), source: makeSource())
        }
    }

    @Test("a signature bound to another network is rejected")
    func verificationRejectsForeignChain() throws {
        let preSignature = try makePreSignature(amount: "8460000", chainId: 137)

        #expect(throws: (any Error).self) {
            try verify(preSignature, target: makeTarget(), source: makeSource())
        }
    }

    @Test("a signature bound to another token is rejected")
    func verificationRejectsForeignAsset() throws {
        let preSignature = try makePreSignature(amount: "8460000", chainId: 8453, asset: Self.foreignAsset)

        #expect(throws: (any Error).self) {
            try verify(preSignature, target: makeTarget(), source: makeSource())
        }
    }

    @Test("a signature bound to another collateral contract is rejected")
    func verificationRejectsForeignContract() throws {
        var fixture = makeFixture()
        fixture.verifyingContract = Self.foreignCollateral

        let preSignature = try fixture.makePreSignature()

        #expect(throws: (any Error).self) {
            try verify(preSignature, target: makeTarget(), source: makeSource())
        }
    }

    @Test("a struct other than the collateral Withdraw is rejected")
    func verificationRejectsForeignPrimaryType() throws {
        var fixture = makeFixture()
        fixture.primaryType = "AddAdmin"

        let preSignature = try fixture.makePreSignature()

        #expect(throws: (any Error).self) {
            try verify(preSignature, target: makeTarget(), source: makeSource())
        }
    }

    @Test("a checked value the struct does not declare is rejected")
    func verificationRejectsUndeclaredField() throws {
        var fixture = makeFixture()
        fixture.messageFields = ["address user", "address asset", "uint256 amount", "uint256 nonce"]

        let preSignature = try fixture.makePreSignature()

        #expect(throws: (any Error).self) {
            try verify(preSignature, target: makeTarget(), source: makeSource())
        }
    }

    @Test("a type beyond the collateral schema is rejected")
    func verificationRejectsExtraType() throws {
        var fixture = makeFixture()
        fixture.extraTypes = ["Permit": ["uint256 value"]]

        let preSignature = try fixture.makePreSignature()

        #expect(throws: (any Error).self) {
            try verify(preSignature, target: makeTarget(), source: makeSource())
        }
    }

    @Test("a domain with another name is rejected")
    func verificationRejectsForeignDomainName() throws {
        var fixture = makeFixture()
        fixture.domainName = "Permit2"

        let preSignature = try fixture.makePreSignature()

        #expect(throws: (any Error).self) {
            try verify(preSignature, target: makeTarget(), source: makeSource())
        }
    }

    @Test("a domain with another version is rejected")
    func verificationRejectsForeignDomainVersion() throws {
        var fixture = makeFixture()
        fixture.domainVersion = "1"

        let preSignature = try fixture.makePreSignature()

        #expect(throws: (any Error).self) {
            try verify(preSignature, target: makeTarget(), source: makeSource())
        }
    }

    @Test("the chain id survives being quoted as a string")
    func verificationAcceptsStringChainId() throws {
        let preSignature = try makePreSignature(amount: "8460000", chainId: 8453, quotesChainId: true)

        try verify(preSignature, target: makeTarget(), source: makeSource())
    }

    @Test("a BNB Smart Chain withdrawal is scaled by eighteen decimals — its stables are Binance-Peg")
    func verificationUsesBSCDecimals() throws {
        let bscChainId = 56
        // 8.46 * 10^18, the largest scale that still fits the Int the message amount is read as.
        let preSignature = try makePreSignature(amount: "8460000000000000000", chainId: bscChainId)

        try verify(preSignature, target: makeTarget(chainId: bscChainId), source: makeSource(chainId: bscChainId))
    }

    @Test("the message amount survives being quoted as a string")
    func verificationAcceptsStringAmount() throws {
        let preSignature = try makePreSignature(amount: "\"8460000\"", chainId: 8453)

        try verify(preSignature, target: makeTarget(), source: makeSource())
    }

    @Test("the payload as the BFF sends it, with the chain id and amount quoted, verifies")
    func verificationAcceptsBFFShape() throws {
        let preSignature = try makePreSignature(amount: "\"8460000\"", chainId: 8453, quotesChainId: true)

        try verify(preSignature, target: makeTarget(), source: makeSource())
    }

    @Test("a targeted withdrawal is held to its network's deposit address")
    func sourceUsesTargetNetworkDepositAddress() throws {
        let balance = try makeBalance()

        let source = Service.Source(target: makeTarget(), balance: balance)

        #expect(source == Service.Source(
            chainId: 8453,
            tokenContractAddress: Self.asset.lowercased(),
            depositAddress: Self.baseDepositAddress
        ))
    }

    @Test("an untargeted withdrawal is held to the account's default network")
    func sourceUsesDefaultNetworkWhenUntargeted() throws {
        let balance = try makeBalance()

        let source = Service.Source(target: nil, balance: balance)

        #expect(source == Service.Source(
            chainId: balance.crypto.chainId,
            tokenContractAddress: balance.crypto.tokenContractAddress,
            depositAddress: balance.crypto.depositAddress
        ))
    }

    @Test("a network the account doesn't hold has no source")
    func sourceIsMissingForUnknownNetwork() throws {
        let balance = try makeBalance()

        let source = Service.Source(target: makeTarget(chainId: 42161), balance: balance)

        #expect(source == nil)
    }

    // MARK: - Helpers

    private func verify(
        _ preSignature: TangemPayWithdrawPreSignature,
        target: TangemPayWithdrawTarget?,
        source: Service.Source
    ) throws {
        try Service.verifyPreSignature(
            preSignature,
            against: makeRequest(target: target),
            source: source,
            fiatItem: TangemPayUtilities.fiatItem
        )
    }

    private func makeTarget(chainId: Int = 8453) -> TangemPayWithdrawTarget {
        TangemPayWithdrawTarget(
            chainId: chainId,
            // The BFF echoes contract addresses in an arbitrary checksum casing.
            tokenContractAddress: Self.asset.lowercased()
        )
    }

    private func makeSource(chainId: Int = 8453) -> Service.Source {
        Service.Source(
            chainId: chainId,
            tokenContractAddress: Self.asset.lowercased(),
            depositAddress: TangemPayWithdrawTypedDataFixture.collateral.lowercased()
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
        try makeFixture(amount: amount, chainId: chainId, asset: asset, quotesChainId: quotesChainId).makePreSignature()
    }

    private func makeFixture(
        amount: String = "8460000",
        chainId: Int = 8453,
        asset: String = TangemPayWithdrawPreSignatureVerificationTests.asset,
        quotesChainId: Bool = false
    ) -> TangemPayWithdrawTypedDataFixture {
        TangemPayWithdrawTypedDataFixture(
            chainId: chainId,
            quotesChainId: quotesChainId,
            asset: asset,
            recipient: Self.recipient,
            amount: amount
        )
    }

    private func makeBalance() throws -> TangemPayBalance {
        try makeTangemPayBalance(
            networks: """
            [
              {
                "name": "\(Blockchain.polygon(testnet: false).networkId)",
                "isTestnet": false,
                "chainId": 137,
                "status": "ENABLED",
                "depositAddress": "0xdeposit",
                "tokens": []
              },
              {
                "name": "\(Blockchain.base(testnet: false).networkId)",
                "isTestnet": false,
                "chainId": 8453,
                "status": "ENABLED",
                "depositAddress": "\(Self.baseDepositAddress)",
                "tokens": []
              }
            ]
            """
        )
    }
}
