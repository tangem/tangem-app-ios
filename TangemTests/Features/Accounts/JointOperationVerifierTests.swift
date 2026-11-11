//
//  JointOperationVerifierTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BigInt
import BlockchainSdk
@testable import Tangem

@Suite("JointOperationVerifier")
struct JointOperationVerifierTests {
    private let verifier = JointOperationVerifier()

    @Test("A well-formed operation whose votes recover to members passes")
    func validOperationPasses() throws {
        let fixture = try makeFixture()

        try verifier.verify(
            operation: fixture.operation,
            safeAddress: Constants.safeAddress,
            memberAddresses: fixture.memberAddresses,
            feeBounds: makeBounds()
        )
    }

    @Test("A vote from an address outside the composition is rejected")
    func nonMemberVoteIsRejected() throws {
        let fixture = try makeFixture()

        expectVerification(.voteMismatch) {
            try verifier.verify(
                operation: fixture.operation,
                safeAddress: Constants.safeAddress,
                memberAddresses: [Constants.stranger],
                feeBounds: makeBounds()
            )
        }
    }

    @Test("A vote whose signature does not recover to the member it names is rejected")
    func nonRecoveringVoteIsRejected() throws {
        let safeTransaction = makeSafeTransaction()
        let member = try JointOperationVoteFixture.approve(over: safeTransaction, chainId: Constants.chainId, safeAddress: Constants.safeAddress).address
        let forgedVote = JointAccountOperation.Signature(address: member, state: .signed, signature: Constants.forgedSignature, at: Constants.at)
        let operation = makeOperation(safeTransaction: safeTransaction, initiator: member, signatures: [forgedVote])

        expectVerification(.voteMismatch) {
            try verifier.verify(operation: operation, safeAddress: Constants.safeAddress, memberAddresses: [member], feeBounds: makeBounds())
        }
    }

    @Test("An operation whose initiator has not approved is rejected")
    func missingInitiatorVoteIsRejected() throws {
        let safeTransaction = makeSafeTransaction()
        let vote = try JointOperationVoteFixture.approve(over: safeTransaction, chainId: Constants.chainId, safeAddress: Constants.safeAddress)
        let operation = makeOperation(safeTransaction: safeTransaction, initiator: Constants.stranger, signatures: [vote.signature])

        expectVerification(.voteMismatch) {
            try verifier.verify(operation: operation, safeAddress: Constants.safeAddress, memberAddresses: [vote.address, Constants.stranger], feeBounds: makeBounds())
        }
    }

    @Test("A refund receiver that is not the treasury is rejected")
    func foreignRefundReceiverIsRejected() throws {
        let fixture = try makeFixture(safeTransaction: makeSafeTransaction(refundReceiver: Constants.stranger))

        expectVerification(.refundMismatch) {
            try verifier.verify(operation: fixture.operation, safeAddress: Constants.safeAddress, memberAddresses: fixture.memberAddresses, feeBounds: makeBounds())
        }
    }

    @Test("A base gas that is neither the base nor the base plus deploy is rejected")
    func invalidBaseGasIsRejected() throws {
        let fixture = try makeFixture(safeTransaction: makeSafeTransaction(baseGas: BigUInt(100_000)))

        expectVerification(.refundMismatch) {
            try verifier.verify(operation: fixture.operation, safeAddress: Constants.safeAddress, memberAddresses: fixture.memberAddresses, feeBounds: makeBounds())
        }
    }

    @Test("A gas token that is not the coin or an allowed fee token is rejected")
    func disallowedGasTokenIsRejected() throws {
        let fixture = try makeFixture(safeTransaction: makeSafeTransaction(gasToken: Constants.stranger))

        expectVerification(.refundMismatch) {
            try verifier.verify(operation: fixture.operation, safeAddress: Constants.safeAddress, memberAddresses: fixture.memberAddresses, feeBounds: makeBounds())
        }
    }

    @Test("A gas price above the ceiling is rejected at Sign")
    func gasPriceAboveCeilingIsRejected() throws {
        let fixture = try makeFixture(safeTransaction: makeSafeTransaction(gasPrice: BigUInt(10_000_000_000)))

        expectVerification(.refundMismatch) {
            try verifier.verify(operation: fixture.operation, safeAddress: Constants.safeAddress, memberAddresses: fixture.memberAddresses, feeBounds: makeBounds(gasPriceCeiling: BigUInt(1_000_000_000)))
        }
    }

    @Test("The gas-price ceiling is not applied when it is absent (display)")
    func gasPriceCeilingSkippedWhenAbsent() throws {
        let fixture = try makeFixture(safeTransaction: makeSafeTransaction(gasPrice: BigUInt(10_000_000_000)))

        try verifier.verify(
            operation: fixture.operation,
            safeAddress: Constants.safeAddress,
            memberAddresses: fixture.memberAddresses,
            feeBounds: makeBounds(gasPriceCeiling: nil)
        )
    }
}

// MARK: - Helpers

private extension JointOperationVerifierTests {
    func expectVerification(_ failure: JointOperationVerificationFailure, _ operation: () throws -> Void) {
        #expect(throws: JointOperationError.operationVerificationFailed(failure)) {
            try operation()
        }
    }

    func makeSafeTransaction(
        to: String = Constants.recipient,
        baseGas: BigUInt = JointOperationFeeConstants.baseGas,
        gasPrice: BigUInt = BigUInt(1_000_000_000),
        gasToken: String = SafeGasToken.coinGasTokenRawValue,
        refundReceiver: String = JointOperationFeeConstants.refundReceiver
    ) -> SafeTransaction {
        SafeTransaction(
            to: to,
            value: BigUInt(1_000_000_000_000_000),
            data: Data(),
            operation: 0,
            safeTxGas: BigUInt(50_000),
            baseGas: baseGas,
            gasPrice: gasPrice,
            gasToken: gasToken,
            refundReceiver: refundReceiver,
            nonce: 0
        )
    }

    func makeOperation(safeTransaction: SafeTransaction, initiator: String, signatures: [JointAccountOperation.Signature]) -> JointAccountOperation {
        JointAccountOperation(
            id: "op",
            chainId: Constants.chainId,
            safeTransaction: safeTransaction,
            status: .awaitingSignatures,
            txHash: nil,
            finishedAt: nil,
            cancelReason: nil,
            initiator: initiator,
            signatures: signatures,
            createdAt: Date(timeIntervalSince1970: 1_757_323_237),
            threshold: 2
        )
    }

    func makeFixture(safeTransaction: SafeTransaction? = nil) throws -> (operation: JointAccountOperation, memberAddresses: [String]) {
        let safeTransaction = safeTransaction ?? makeSafeTransaction()
        let vote = try JointOperationVoteFixture.approve(over: safeTransaction, chainId: Constants.chainId, safeAddress: Constants.safeAddress)
        let operation = makeOperation(safeTransaction: safeTransaction, initiator: vote.address, signatures: [vote.signature])
        return (operation, [vote.address])
    }

    func makeBounds(gasPriceCeiling: BigUInt? = nil) -> JointOperationVerifier.FeeBounds {
        JointOperationVerifier.FeeBounds(
            refundReceiver: JointOperationFeeConstants.refundReceiver,
            allowedGasTokenAddresses: [SafeGasToken.coinGasTokenRawValue.lowercased()],
            gasPriceCeiling: gasPriceCeiling
        )
    }

    enum Constants {
        static let chainId = 1
        static let safeAddress = "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"
        static let recipient = "0x2222222222222222222222222222222222222222"
        static let stranger = "0x1111111111111111111111111111111111111111"
        static let at = "2026-09-02T10:15:00Z"
        static let forgedSignature = "0x1111111111111111111111111111111111111111111111111111111111111111222222222222222222222222222222222222222222222222222222222222222222221b"
    }
}
