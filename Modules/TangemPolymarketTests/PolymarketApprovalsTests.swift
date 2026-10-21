//
//  PolymarketApprovalsTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("Approvals batch")
struct PolymarketApprovalsTests {
    private static let depositWallet = "0xfAeA0f08159fcF2f573fE24E9E989B0d48f7651B"
    private static let deadline = "1735690200"

    private static let maxUint256 = "115792089237316195423570985008687907853269984665640564039457584007913129639935"

    private static let approveSelector = "0x095ea7b3"
    private static let setApprovalForAllSelector = "0xa22cb465"

    // MARK: - The set the validator expects

    @Test("The batch carries the seventeen calls the backend validates")
    func theBatchHasSeventeenCalls() {
        #expect(PolymarketApprovalCalls.make().count == 17)
    }

    @Test("Eight allowances are granted on the collateral, seven on the conditional tokens, two on the position manager")
    func callsSplitBetweenTheTokens() {
        let calls = PolymarketApprovalCalls.make()

        #expect(calls.filter { $0.target == PolymarketCollateral.contractAddress }.count == 8)
        #expect(calls.filter { $0.target == PolymarketApprovalContracts.conditionalTokens }.count == 7)
        #expect(calls.filter { $0.target == PolymarketApprovalContracts.positionManager }.count == 2)
    }

    @Test("The V2 operators are approved on the token that holds their positions", arguments: [
        OperatorGrant(token: PolymarketApprovalContracts.positionManager, operatorAddress: PolymarketApprovalContracts.exchangeV3),
        OperatorGrant(token: PolymarketApprovalContracts.positionManager, operatorAddress: PolymarketApprovalContracts.routerV3),
        OperatorGrant(token: PolymarketApprovalContracts.conditionalTokens, operatorAddress: PolymarketApprovalContracts.binaryModule),
        OperatorGrant(token: PolymarketApprovalContracts.conditionalTokens, operatorAddress: PolymarketApprovalContracts.negRiskModule),
    ])
    func v2OperatorsAreApproved(grant: OperatorGrant) {
        let operatorWord = String(repeating: "0", count: 24) + grant.operatorAddress.dropFirst(2).lowercased()
        let expected = Self.setApprovalForAllSelector + operatorWord + String(repeating: "0", count: 63) + "1"

        #expect(PolymarketApprovalCalls.make().contains { $0.target == grant.token && $0.data == expected })
    }

    @Test("Every call is one of the two expected selectors and moves no coin")
    func callsAreWellFormed() {
        for call in PolymarketApprovalCalls.make() {
            #expect(call.value == "0")
            #expect(call.data.hasPrefix(Self.approveSelector) || call.data.hasPrefix(Self.setApprovalForAllSelector))
            #expect(call.data.count == 10 + 64 * 2)
        }
    }

    @Test("Each spender is granted an allowance exactly once per token standard")
    func spendersAreNotDuplicated() {
        let calls = PolymarketApprovalCalls.make()

        #expect(Set(calls.map(\.data)).count == calls.count)
    }

    @Test("Approvals grant the maximum allowance and set the flag to true")
    func amountsAreTheExpectedConstants() {
        for call in PolymarketApprovalCalls.make() {
            let argument = String(call.data.suffix(64))

            if call.data.hasPrefix(Self.approveSelector) {
                #expect(argument == String(repeating: "f", count: 64))
            } else {
                #expect(argument == String(repeating: "0", count: 63) + "1")
            }
        }
    }

    // MARK: - The digest the card signs

    @Test("The digest matches an independently computed vector", arguments: [
        Vector(nonce: "0", digest: "bdb41c03f6c32a72a73ca7b7baff7e1fb55b066fb73e048c270c32a0f6157d21"),
        Vector(nonce: "7", digest: "f2f3e2e6dea85743224e6eb632ddbb6ad8533c9ecd2c5b61061dfec0a2f4f829"),
    ])
    func digestMatchesTheVector(vector: Vector) throws {
        let digest = try PolymarketRelayedBatchSigning.digest(
            for: .init(
                depositWalletAddress: Self.depositWallet,
                nonce: vector.nonce,
                deadline: Self.deadline,
                calls: PolymarketApprovalCalls.make()
            )
        )

        #expect(digest.map { String(format: "%02x", $0) }.joined() == vector.digest)
    }

    @Test("Reordering the calls signs a different batch")
    func theCallOrderIsPartOfTheDigest() throws {
        let calls = PolymarketApprovalCalls.make()
        let digest = try Self.makeDigest(calls: calls)
        let reordered = try Self.makeDigest(calls: calls.reversed())

        #expect(digest != reordered)
    }

    @Test("The deposit wallet is part of the digest, both as the domain and as the message")
    func theDepositWalletIsPartOfTheDigest() throws {
        let digest = try Self.makeDigest(calls: PolymarketApprovalCalls.make())
        let other = try PolymarketRelayedBatchSigning.digest(
            for: .init(
                depositWalletAddress: "0x0491eb219E3D2d05aEF0C35D1079c0a55b19bd2B",
                nonce: "0",
                deadline: Self.deadline,
                calls: PolymarketApprovalCalls.make()
            )
        )

        #expect(digest != other)
    }

    @Test("The deadline is part of the digest")
    func theDeadlineIsPartOfTheDigest() throws {
        let digest = try Self.makeDigest(calls: PolymarketApprovalCalls.make())
        let other = try PolymarketRelayedBatchSigning.digest(
            for: .init(
                depositWalletAddress: Self.depositWallet,
                nonce: "0",
                deadline: "1735690800",
                calls: PolymarketApprovalCalls.make()
            )
        )

        #expect(digest != other)
    }

    @Test("A nonce that is not a number is rejected instead of silently signed", arguments: ["", "seven", "7.5", "-7", "0x7"])
    func malformedNonceIsRejected(nonce: String) {
        #expect(throws: PolymarketRelayedBatchSigningError.invalidNonce) {
            try PolymarketRelayedBatchSigning.digest(
                for: .init(
                    depositWalletAddress: Self.depositWallet,
                    nonce: nonce,
                    deadline: Self.deadline,
                    calls: PolymarketApprovalCalls.make()
                )
            )
        }
    }

    @Test("A deadline that is not a number is rejected instead of silently signed")
    func malformedDeadlineIsRejected() {
        #expect(throws: PolymarketRelayedBatchSigningError.invalidDeadline) {
            try PolymarketRelayedBatchSigning.digest(
                for: .init(
                    depositWalletAddress: Self.depositWallet,
                    nonce: "0",
                    deadline: "tomorrow",
                    calls: PolymarketApprovalCalls.make()
                )
            )
        }
    }

    @Test("A value too large for uint256 is rejected instead of truncating the digest", arguments: [
        Self.maxUint256 + "0",
        "115792089237316195423570985008687907853269984665640564039457584007913129639936",
        String(repeating: "9", count: 78),
    ])
    func nonceAndDeadlineBeyondUint256AreRejected(value: String) {
        #expect(throws: PolymarketRelayedBatchSigningError.invalidNonce) {
            try PolymarketRelayedBatchSigning.digest(
                for: .init(
                    depositWalletAddress: Self.depositWallet,
                    nonce: value,
                    deadline: Self.deadline,
                    calls: PolymarketApprovalCalls.make()
                )
            )
        }

        #expect(throws: PolymarketRelayedBatchSigningError.invalidDeadline) {
            try PolymarketRelayedBatchSigning.digest(
                for: .init(
                    depositWalletAddress: Self.depositWallet,
                    nonce: "0",
                    deadline: value,
                    calls: PolymarketApprovalCalls.make()
                )
            )
        }
    }

    @Test("The largest value uint256 can hold is still signed", arguments: [Self.maxUint256, "0" + Self.maxUint256])
    func theUpperBoundIsAccepted(value: String) throws {
        let digest = try PolymarketRelayedBatchSigning.digest(
            for: .init(
                depositWalletAddress: Self.depositWallet,
                nonce: value,
                deadline: Self.deadline,
                calls: PolymarketApprovalCalls.make()
            )
        )

        #expect(digest.count == 32)
    }

    @Test("A deposit wallet the encoder cannot parse is rejected instead of signed", arguments: [
        "",
        "fAeA0f08159fcF2f573fE24E9E989B0d48f7651B",
        "0xfAeA0f08159fcF2f573fE24E9E989B0d48f765",
        "0xfAeA0f08159fcF2f573fE24E9E989B0d48f7651BB",
        "0xfAeA0f08159fcF2f573fE24E9E989B0d48f7651Z",
    ])
    func malformedDepositWalletIsRejected(address: String) {
        #expect(throws: PolymarketRelayedBatchSigningError.invalidDepositWalletAddress) {
            try PolymarketRelayedBatchSigning.digest(
                for: .init(
                    depositWalletAddress: address,
                    nonce: "0",
                    deadline: Self.deadline,
                    calls: PolymarketApprovalCalls.make()
                )
            )
        }
    }
}

// MARK: - Fixtures

extension PolymarketApprovalsTests {
    struct Vector: Sendable {
        let nonce: String
        let digest: String
    }

    struct OperatorGrant: Sendable {
        let token: String
        let operatorAddress: String
    }
}

private extension PolymarketApprovalsTests {
    static func makeDigest(calls: [PolymarketRelayedBatch.Call]) throws -> Data {
        try PolymarketRelayedBatchSigning.digest(
            for: .init(
                depositWalletAddress: depositWallet,
                nonce: "0",
                deadline: deadline,
                calls: calls
            )
        )
    }
}
