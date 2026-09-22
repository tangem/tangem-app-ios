//
//  CommonPolymarketOnboardingSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation
import TangemPolymarket

final class CommonPolymarketOnboardingSigner {
    private let keysRepository: KeysRepository
    private let signer: TangemSigner

    init(keysRepository: KeysRepository, signer: TangemSigner) {
        self.keysRepository = keysRepository
        self.signer = signer
    }
}

// MARK: - PolymarketOnboardingSigning protocol conformance

extension CommonPolymarketOnboardingSigner: PolymarketOnboardingSigning {
    func sign(
        approvals: PolymarketRelayedBatch.Unsigned
    ) async throws(PolymarketSigningError) -> PolymarketOnboardingSignatures {
        guard let ownerKey = PolymarketUtilities.getKey(from: keysRepository) else { throw .notDerived }

        let ownerAddress = try makeOwnerAddress(using: ownerKey)
        let timestamp = String(Int(Date().timeIntervalSince1970))

        let authDigest = PolymarketClobAuth.digest(ownerAddress: ownerAddress, timestamp: timestamp)
        let batchDigest = try makeBatchDigest(for: approvals)

        let signatures = try await makeSignatures(auth: authDigest, batch: batchDigest, using: ownerKey)

        return PolymarketOnboardingSignatures(
            authHeaders: PolymarketCLOBAuthHeaders(
                ownerAddress: ownerAddress,
                signature: signatures.auth,
                timestamp: timestamp,
                nonce: PolymarketClobAuth.nonce
            ),
            approvals: approvals.signed(by: ownerAddress, signature: signatures.batch)
        )
    }
}

// MARK: - Private implementation

private extension CommonPolymarketOnboardingSigner {
    func makeOwnerAddress(using ownerKey: Wallet.PublicKey) throws(PolymarketSigningError) -> String {
        do {
            return try PolymarketUtilities.makeAddress(using: ownerKey)
        } catch {
            PolymarketLogger.error("Failed to make the owner address", error: error)
            throw .addressCreationFailed
        }
    }

    func makeBatchDigest(for approvals: PolymarketRelayedBatch.Unsigned) throws(PolymarketSigningError) -> Data {
        do {
            return try PolymarketRelayedBatchSigning.digest(for: approvals)
        } catch {
            PolymarketLogger.error("Failed to build the approvals digest", error: error)
            throw .unknown
        }
    }

    func makeSignatures(
        auth authDigest: Data,
        batch batchDigest: Data,
        using ownerKey: Wallet.PublicKey
    ) async throws(PolymarketSigningError) -> (auth: String, batch: String) {
        do {
            let signatures = try await signer
                .sign(hashes: [authDigest, batchDigest], walletPublicKey: ownerKey)
                .async()

            let unmarshalled = try signatures.map { try $0.unmarshal().hexString.lowercased().addHexPrefix() }

            guard unmarshalled.count == 2, let auth = unmarshalled.first, let batch = unmarshalled.last else {
                throw PolymarketSigningError.unknown
            }

            return (auth: auth, batch: batch)
        } catch {
            PolymarketLogger.error("Failed to sign the onboarding digests", error: error)
            throw PolymarketSigningError(signingFailure: error)
        }
    }
}
