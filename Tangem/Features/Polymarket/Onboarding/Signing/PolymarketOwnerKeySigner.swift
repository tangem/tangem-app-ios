//
//  PolymarketOwnerKeySigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol PolymarketOwnerKeySigner {
    func sign(hashes: [Data], ownerKey: Wallet.PublicKey) async throws -> [SignatureInfo]
}

struct TangemPolymarketOwnerKeySigner: PolymarketOwnerKeySigner {
    private let signer: TangemSigner

    init(signer: TangemSigner) {
        self.signer = signer
    }

    func sign(hashes: [Data], ownerKey: Wallet.PublicKey) async throws -> [SignatureInfo] {
        try await signer
            .sign(hashes: hashes, walletPublicKey: ownerKey)
            .async()
    }
}
