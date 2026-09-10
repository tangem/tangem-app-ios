//
//  CommonPolymarketOrderDigestSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation
import TangemPolymarket

final class CommonPolymarketOrderDigestSigner {
    private let keysRepository: KeysRepository
    private let signer: TangemSigner

    init(keysRepository: KeysRepository, signer: TangemSigner) {
        self.keysRepository = keysRepository
        self.signer = signer
    }
}

// MARK: - PolymarketOrderDigestSigning protocol conformance

extension CommonPolymarketOrderDigestSigner: PolymarketOrderDigestSigning {
    func sign(digest: Data) async throws -> String {
        guard let ownerKey = PolymarketUtilities.getKey(from: keysRepository) else {
            throw PolymarketSigningError.notDerived
        }

        do {
            let signatures = try await signer.sign(hashes: [digest], walletPublicKey: ownerKey).async()

            guard let signature = signatures.first else {
                throw PolymarketSigningError.unknown
            }

            return try signature.unmarshal().hexString.lowercased().addHexPrefix()
        } catch {
            PolymarketLogger.error("Failed to sign the order digest", error: error)
            throw PolymarketSigningError(signingFailure: error)
        }
    }
}
