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
    private let signer: PolymarketOwnerKeySigner

    init(keysRepository: KeysRepository, signer: PolymarketOwnerKeySigner) {
        self.keysRepository = keysRepository
        self.signer = signer
    }

    convenience init(keysRepository: KeysRepository, signer: TangemSigner) {
        self.init(keysRepository: keysRepository, signer: TangemPolymarketOwnerKeySigner(signer: signer))
    }
}

// MARK: - PolymarketOnboardingSigning protocol conformance

extension CommonPolymarketOnboardingSigner: PolymarketOnboardingSigning {
    func sign(
        approvals: PolymarketRelayedBatch.Unsigned,
        fastTradingAuthorization: PolymarketRelayedBatch.Unsigned?
    ) async throws(PolymarketSigningError) -> PolymarketOnboardingSignatures {
        guard let ownerKey = PolymarketUtilities.getKey(from: keysRepository) else { throw .notDerived }

        let ownerAddress = try makeOwnerAddress(using: ownerKey)
        let timestamp = String(Int(Date().timeIntervalSince1970))

        let authDigest = PolymarketClobAuth.digest(ownerAddress: ownerAddress, timestamp: timestamp)
        var batchDigests = [try makeBatchDigest(for: approvals)]

        if let fastTradingAuthorization {
            batchDigests.append(try makeBatchDigest(for: fastTradingAuthorization))
        }

        let signatures = try await makeSignatures(auth: authDigest, batches: batchDigests, using: ownerKey)

        guard let approvalsSignature = signatures.batches.first else {
            throw .unknown
        }

        let fastTradingAuthorizationSignature = signatures.batches.dropFirst().first

        return PolymarketOnboardingSignatures(
            authHeaders: PolymarketCLOBAuthHeaders(
                ownerAddress: ownerAddress,
                signature: signatures.auth,
                timestamp: timestamp,
                nonce: PolymarketClobAuth.nonce
            ),
            approvals: approvals.signed(by: ownerAddress, signature: approvalsSignature),
            fastTradingAuthorization: fastTradingAuthorizationSignature.flatMap { signature in
                fastTradingAuthorization?.signed(by: ownerAddress, signature: signature)
            }
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

    func makeBatchDigest(for batch: PolymarketRelayedBatch.Unsigned) throws(PolymarketSigningError) -> Data {
        do {
            return try PolymarketRelayedBatchSigning.digest(for: batch)
        } catch {
            PolymarketLogger.error("Failed to build the onboarding batch digest", error: error)
            throw .unknown
        }
    }

    func makeSignatures(
        auth authDigest: Data,
        batches batchDigests: [Data],
        using ownerKey: Wallet.PublicKey
    ) async throws(PolymarketSigningError) -> (auth: String, batches: [String]) {
        do {
            let signatures = try await signer.sign(hashes: [authDigest] + batchDigests, ownerKey: ownerKey)

            let unmarshalled = try signatures.map { try $0.unmarshal().hexString.lowercased().addHexPrefix() }

            guard unmarshalled.count == batchDigests.count + 1, let auth = unmarshalled.first else {
                throw PolymarketSigningError.unknown
            }

            return (auth: auth, batches: Array(unmarshalled.dropFirst()))
        } catch {
            PolymarketLogger.error("Failed to sign the onboarding digests", error: error)
            throw PolymarketSigningError(signingFailure: error)
        }
    }
}
