//
//  JointOperationVerifier.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import BlockchainSdk
import TangemFoundation

struct JointOperationVerifier {
    private let formVerifier = JointOperationFormVerifier()

    func verify(
        operation: JointAccountOperation,
        safeAddress: String,
        memberAddresses: [String],
        feeBounds: FeeBounds
    ) throws {
        try formVerifier.verify(safeTransaction: operation.safeTransaction, safeAddress: safeAddress)
        try verifyFee(operation.safeTransaction, bounds: feeBounds)

        if operation.status.isInFlight {
            try verifyVotes(operation: operation, safeAddress: safeAddress, memberAddresses: memberAddresses)
        }
    }

    private func verifyFee(_ safeTransaction: SafeTransaction, bounds: FeeBounds) throws {
        guard bounds.allowedGasTokenAddresses.contains(safeTransaction.gasToken.lowercased()) else {
            throw JointOperationError.operationVerificationFailed(.refundMismatch)
        }

        let refundReceiver = safeTransaction.refundReceiver
        guard !refundReceiver.caseInsensitiveEquals(to: JointOperationFeeConstants.zeroAddress),
              refundReceiver.caseInsensitiveEquals(to: bounds.refundReceiver) else {
            throw JointOperationError.operationVerificationFailed(.refundMismatch)
        }

        guard JointOperationFeeConstants.allowedBaseGas.contains(safeTransaction.baseGas) else {
            throw JointOperationError.operationVerificationFailed(.refundMismatch)
        }

        if let gasPriceCeiling = bounds.gasPriceCeiling, safeTransaction.gasPrice > gasPriceCeiling {
            throw JointOperationError.operationVerificationFailed(.refundMismatch)
        }
    }

    private func verifyVotes(operation: JointAccountOperation, safeAddress: String, memberAddresses: [String]) throws {
        let approvals = operation.signatures.filter { $0.state == .signed }

        guard approvals.contains(where: { $0.address.caseInsensitiveEquals(to: operation.initiator) }) else {
            throw JointOperationError.operationVerificationFailed(.voteMismatch)
        }

        let digest = operation.safeTransaction.signHash(chainId: operation.chainId, safeAddress: safeAddress)

        for approval in approvals {
            guard let signature = approval.signature,
                  memberAddresses.contains(where: { $0.caseInsensitiveEquals(to: approval.address) }),
                  let recovered = try? JointSafeSignatureRecoverer.recoverSigner(ofDigest: digest, signature: signature),
                  recovered.caseInsensitiveEquals(to: approval.address)
            else {
                throw JointOperationError.operationVerificationFailed(.voteMismatch)
            }
        }
    }
}

// MARK: - Auxiliary types

extension JointOperationVerifier {
    struct FeeBounds {
        let refundReceiver: String
        let allowedGasTokenAddresses: Set<String>
        let gasPriceCeiling: BigUInt?
    }
}

enum JointOperationVerificationFailure: Equatable {
    case refundMismatch
    case voteMismatch
}
