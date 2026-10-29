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
