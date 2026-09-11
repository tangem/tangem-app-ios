//
//  CommonPolymarketClobAuthSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation
import TangemPolymarket
import TangemSdk

final class CommonPolymarketClobAuthSigner {
    private let keysRepository: KeysRepository
    private let signer: TangemSigner

    init(keysRepository: KeysRepository, signer: TangemSigner) {
        self.keysRepository = keysRepository
        self.signer = signer
    }
}

// MARK: - PolymarketClobAuthSigning protocol conformance

extension CommonPolymarketClobAuthSigner: PolymarketClobAuthSigning {
    func sign() async throws(PolymarketSigningError) -> PolymarketCLOBAuthHeaders {
        guard let ownerKey = PolymarketUtilities.getKey(from: keysRepository) else {
            throw .notDerived
        }

        let ownerAddress = try makeOwnerAddress(using: ownerKey)
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let digest = PolymarketClobAuth.digest(ownerAddress: ownerAddress, timestamp: timestamp)
        let signature = try await makeSignature(digest: digest, using: ownerKey)

        return PolymarketCLOBAuthHeaders(
            ownerAddress: ownerAddress,
            signature: signature,
            timestamp: timestamp,
            nonce: PolymarketClobAuth.nonce
        )
    }
}

// MARK: - Private implementation

private extension CommonPolymarketClobAuthSigner {
    func makeOwnerAddress(using ownerKey: Wallet.PublicKey) throws(PolymarketSigningError) -> String {
        do {
            return try PolymarketUtilities.makeAddress(using: ownerKey)
        } catch {
            PolymarketLogger.error("Failed to make the owner address", error: error)
            throw .addressCreationFailed
        }
    }

    func makeSignature(digest: Data, using ownerKey: Wallet.PublicKey) async throws(PolymarketSigningError) -> String {
        do {
            let signature = try await signer
                .sign(hash: digest, walletPublicKey: ownerKey)
                .async()

            return try signature.unmarshal().hexString.lowercased().addHexPrefix()
        } catch {
            PolymarketLogger.error("Failed to sign the ClobAuth digest", error: error)
            throw PolymarketSigningError(signingFailure: error)
        }
    }
}
