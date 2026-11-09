//
//  PolymarketBatchSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation
import TangemPolymarket

struct PolymarketBatchSigner {
    let keysRepository: KeysRepository
    let signer: TangemSigner
}

// MARK: - PolymarketBatchSigning protocol conformance

extension PolymarketBatchSigner: PolymarketBatchSigning {
    func sign(
        _ batch: PolymarketRelayedBatch.Unsigned,
        as ownerAddress: String
    ) async throws(PolymarketSigningError) -> PolymarketRelayedBatch {
        guard let ownerKey = PolymarketUtilities.getKey(from: keysRepository) else {
            throw .notDerived
        }

        let digest = try makeDigest(for: batch)
        let signature = try await makeSignature(of: digest, using: ownerKey)

        return batch.signed(by: ownerAddress, signature: signature)
    }
}

// MARK: - PolymarketBatchesSigning protocol conformance

extension PolymarketBatchSigner: PolymarketBatchesSigning {
    func sign(
        _ batches: [PolymarketRelayedBatch.Unsigned],
        ownerAuthTimestamp: String?,
        as ownerAddress: String
    ) async throws(PolymarketSigningError) -> PolymarketSignedBatches {
        guard let ownerKey = PolymarketUtilities.getKey(from: keysRepository) else {
            throw .notDerived
        }

        var digests: [Data] = []

        for batch in batches {
            let digest = try makeDigest(for: batch)
            digests.append(digest)
        }

        if let ownerAuthTimestamp {
            digests.append(PolymarketClobAuth.digest(ownerAddress: ownerAddress, timestamp: ownerAuthTimestamp))
        }

        let signatures = try await makeSignatures(of: digests, using: ownerKey)

        guard signatures.count == digests.count else {
            throw .unknown
        }

        let signedBatches = zip(batches, signatures).map { batch, signature in
            batch.signed(by: ownerAddress, signature: signature)
        }

        let ownerAuthHeaders = ownerAuthTimestamp.flatMap { timestamp in
            signatures.last.map { signature in
                PolymarketCLOBAuthHeaders(
                    ownerAddress: ownerAddress,
                    signature: signature,
                    timestamp: timestamp,
                    nonce: PolymarketClobAuth.nonce
                )
            }
        }

        return PolymarketSignedBatches(batches: signedBatches, ownerAuthHeaders: ownerAuthHeaders)
    }
}

// MARK: - Private implementation

private extension PolymarketBatchSigner {
    func makeDigest(for batch: PolymarketRelayedBatch.Unsigned) throws(PolymarketSigningError) -> Data {
        do {
            return try PolymarketRelayedBatchSigning.digest(for: batch)
        } catch {
            PolymarketLogger.error("Failed to build the relayed batch digest", error: error)
            throw .unknown
        }
    }

    func makeSignatures(of digests: [Data], using ownerKey: Wallet.PublicKey) async throws(PolymarketSigningError) -> [String] {
        do {
            let signatures: [SignatureInfo] = try await signer.sign(hashes: digests, walletPublicKey: ownerKey).async()

            return try signatures.map { try $0.unmarshal().hexString.lowercased().addHexPrefix() }
        } catch {
            PolymarketLogger.error("Failed to sign the relayed batches", error: error)
            throw PolymarketSigningError(signingFailure: error)
        }
    }

    func makeSignature(of digest: Data, using ownerKey: Wallet.PublicKey) async throws(PolymarketSigningError) -> String {
        do {
            let signature = try await signer.sign(hash: digest, walletPublicKey: ownerKey).async()

            return try signature.unmarshal().hexString.lowercased().addHexPrefix()
        } catch {
            PolymarketLogger.error("Failed to sign the relayed batch", error: error)
            throw PolymarketSigningError(signingFailure: error)
        }
    }
}
