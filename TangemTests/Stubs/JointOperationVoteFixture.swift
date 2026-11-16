//
//  JointOperationVoteFixture.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk
@testable import Tangem

enum JointOperationVoteFixture {
    enum FixtureError: Error {
        case couldNotProduceRecoverableVote
    }

    private static let keyPair = try! Secp256k1Utils().generateKeyPair()

    static func approve(
        over safeTransaction: SafeTransaction,
        chainId: Int,
        safeAddress: String,
        at: String = "2026-09-02T10:15:00Z"
    ) throws -> (address: String, signature: JointAccountOperation.Signature) {
        let digest = safeTransaction.signHash(chainId: chainId, safeAddress: safeAddress)
        let raw = try Secp256k1Utils().sign(digest, with: keyPair.privateKey)
        let recoverable = try SignatureInfo(signature: raw, publicKey: keyPair.publicKey, hash: digest.getSHA256()).unmarshal()
        let hex = recoverable.hexString.addHexPrefix()

        guard let address = try? JointSafeSignatureRecoverer.recoverSigner(ofDigest: digest, signature: hex) else {
            throw FixtureError.couldNotProduceRecoverableVote
        }

        return (address, JointAccountOperation.Signature(address: address, state: .signed, signature: hex, at: at))
    }
}
