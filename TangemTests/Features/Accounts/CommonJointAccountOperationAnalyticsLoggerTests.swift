//
//  CommonJointAccountOperationAnalyticsLoggerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("Tests for reporting a signature counted on a joint operation")
struct CommonJointAccountOperationAnalyticsLoggerTests {
    private let sut = CommonJointAccountOperationAnalyticsLogger(
        tokenItem: .blockchain(BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)),
        policy: JointAccountPolicy(membersCount: 3, signersCount: 2)
    )

    @Test("The initiator counts as a signer once, whether or not the listing repeats them")
    func initiatorCountsOnce() {
        let unlisted = operation(signatures: [signature(of: Constants.ownAddress)])
        let listed = operation(signatures: [signature(of: Constants.ownAddress), signature(of: Constants.initiator.uppercased())])

        #expect(sut.operationSignedParameters(for: unlisted)[.signaturesCollected] == "2")
        #expect(sut.operationSignedParameters(for: listed)[.signaturesCollected] == "2")
    }

    @Test("Reaching the threshold is told by the signatures counted")
    func thresholdIsToldByTheCount() {
        let reached = operation(signatures: [signature(of: Constants.ownAddress)])
        let short = operation(signatures: [])

        #expect(sut.operationSignedParameters(for: reached)[.thresholdReached] == "Yes")
        #expect(sut.operationSignedParameters(for: short)[.thresholdReached] == "No")
    }

    @Test("Declined and unread answers are no signatures")
    func otherAnswersAreNoSignatures() {
        let operation = operation(signatures: [
            signature(of: Constants.ownAddress, state: .declined),
            signature(of: "0x9f1e2d3c4b5a69788796a5b4c3d2e1f0a1b2c3d4", state: .unknown),
        ])

        #expect(sut.operationSignedParameters(for: operation)[.signaturesCollected] == "1")
    }

    @Test("The whole report names the composition and the token")
    func reportNamesTheCompositionAndTheToken() {
        let operation = operation(signatures: [signature(of: Constants.ownAddress)])

        #expect(sut.operationSignedParameters(for: operation) == [
            .signaturesCollected: "2",
            .membersCount: "3",
            .threshold: "2",
            .thresholdReached: "Yes",
            .blockchain: "Ethereum",
            .token: "ETH",
        ])
    }

    @Test("Without the account's policy the composition is left out")
    func missingPolicyLeavesTheCompositionOut() {
        let sut = CommonJointAccountOperationAnalyticsLogger(
            tokenItem: .blockchain(BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)),
            policy: nil
        )

        let params = sut.operationSignedParameters(for: operation(signatures: []))

        #expect(params == [.signaturesCollected: "1", .blockchain: "Ethereum", .token: "ETH"])
    }
}

// MARK: - Helpers

private extension CommonJointAccountOperationAnalyticsLoggerTests {
    enum Constants {
        static let initiator = "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf"
        static let ownAddress = "0x3c9e1b7a5d2f80461c8a0e2b4d6f8a0c2e4b6c90"
    }

    func operation(signatures: [JointAccountOperation.Signature]) -> JointAccountOperation {
        JointAccountCompositionFixture.coinTransfer(initiator: Constants.initiator, signatures: signatures)
    }

    func signature(of address: String, state: JointAccountOperation.Signature.State = .signed) -> JointAccountOperation.Signature {
        JointAccountOperation.Signature(address: address, state: state, at: "2026-10-27T10:00:00Z")
    }
}
