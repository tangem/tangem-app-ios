//
//  SolanaALTSendTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

protocol SolanaALTSendTransactionBuilder {
    func buildForSend(message: MessageV0) async throws -> Data
}

struct SolanaCommonALTSendTransactionBuilder: SolanaALTSendTransactionBuilder {
    // MARK: - Properties

    private let walletPublicKey: PublicKey
    private let signer: SolanaTransactionSigner

    // MARK: - Init

    init(walletPublicKey: PublicKey, signer: SolanaTransactionSigner) {
        self.walletPublicKey = walletPublicKey
        self.signer = signer
    }

    // MARK: - Implementation

    func buildForSend(message: MessageV0) async throws -> Data {
        let versionedTx = VersionedTransaction(message: .v0(message))
        let buildForSign = try versionedTx.prepareForSign()
        let signature = try await signer.sign(message: buildForSign)
        try versionedTx.prepareForSend(signatures: [Signature(signature: signature, publicKey: walletPublicKey)])
        return try versionedTx.serialize()
    }
}

struct SolanaDummyALTSendTransactionBuilder: SolanaALTSendTransactionBuilder {
    // MARK: - Properties

    private let walletPublicKey: PublicKey
    private let signature: Data

    // MARK: - Init

    init(walletPublicKey: PublicKey, signature: Data) {
        self.walletPublicKey = walletPublicKey
        self.signature = signature
    }

    // MARK: - Implementation

    func buildForSend(message: MessageV0) async throws -> Data {
        let versionedTx = VersionedTransaction(message: .v0(message))
        try versionedTx.prepareForSend(signatures: [Signature(signature: signature, publicKey: walletPublicKey)])
        let serialized = try versionedTx.serialize()
        return serialized
    }
}
