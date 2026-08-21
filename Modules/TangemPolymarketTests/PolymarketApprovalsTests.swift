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

    private static let approveSelector = "0x095ea7b3"
    private static let setApprovalForAllSelector = "0xa22cb465"

    // MARK: - The set the validator expects

    @Test("The batch carries the thirteen calls the backend validates")
    func theBatchHasThirteenCalls() {
        #expect(PolymarketApprovalCalls.make().count == 13)
    }

    @Test("Eight allowances are granted on the collateral, five on the conditional tokens")
    func callsSplitBetweenTheTwoTokens() {
        let calls = PolymarketApprovalCalls.make()

        #expect(calls.filter { $0.target == PolymarketCollateral.contractAddress }.count == 8)
        #expect(calls.filter { $0.target == PolymarketApprovalContracts.conditionalTokens }.count == 5)
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
        Vector(nonce: "0", digest: "6fd17c637494a09bf666ce28424a055b805e36bb799c74525ac527e39bd4f08c"),
        Vector(nonce: "7", digest: "6dc8f8c5a4cc89a1291aa95210ac97c2ea8b5604c14c3b74e3c086d937eac79d"),
    ])
    func digestMatchesTheVector(vector: Vector) throws {
        let digest = try PolymarketApprovalsSigning.digest(
            depositWalletAddress: Self.depositWallet,
            nonce: vector.nonce,
            deadline: Self.deadline,
            calls: PolymarketApprovalCalls.make()
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
        let other = try PolymarketApprovalsSigning.digest(
            depositWalletAddress: "0x0491eb219E3D2d05aEF0C35D1079c0a55b19bd2B",
            nonce: "0",
            deadline: Self.deadline,
            calls: PolymarketApprovalCalls.make()
        )

        #expect(digest != other)
    }

    @Test("The deadline is part of the digest")
    func theDeadlineIsPartOfTheDigest() throws {
        let digest = try Self.makeDigest(calls: PolymarketApprovalCalls.make())
        let other = try PolymarketApprovalsSigning.digest(
            depositWalletAddress: Self.depositWallet,
            nonce: "0",
            deadline: "1735690800",
            calls: PolymarketApprovalCalls.make()
        )

        #expect(digest != other)
    }

    @Test("A deposit wallet the encoder cannot parse is rejected instead of signed", arguments: [
        "",
        "fAeA0f08159fcF2f573fE24E9E989B0d48f7651B",
        "0xfAeA0f08159fcF2f573fE24E9E989B0d48f765",
        "0xfAeA0f08159fcF2f573fE24E9E989B0d48f7651BB",
        "0xfAeA0f08159fcF2f573fE24E9E989B0d48f7651Z",
    ])
    func malformedDepositWalletIsRejected(address: String) {
        #expect(throws: PolymarketApprovalsSigningError.invalidDepositWalletAddress) {
            try PolymarketApprovalsSigning.digest(
                depositWalletAddress: address,
                nonce: "0",
                deadline: Self.deadline,
                calls: PolymarketApprovalCalls.make()
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
}

private extension PolymarketApprovalsTests {
    static func makeDigest(calls: [PolymarketApprovalsBatch.Call]) throws -> Data {
        try PolymarketApprovalsSigning.digest(
            depositWalletAddress: depositWallet,
            nonce: "0",
            deadline: deadline,
            calls: calls
        )
    }
}
