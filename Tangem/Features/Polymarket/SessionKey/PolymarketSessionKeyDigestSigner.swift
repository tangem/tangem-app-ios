//
//  PolymarketSessionKeyDigestSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

struct PolymarketSessionKeyDigestSigner {
    private let userWalletId: UserWalletId
    private let keyStore: any PolymarketSessionKeyStore

    init(userWalletId: UserWalletId, keyStore: any PolymarketSessionKeyStore) {
        self.userWalletId = userWalletId
        self.keyStore = keyStore
    }
}

// MARK: - PolymarketOrderDigestSigning protocol conformance

extension PolymarketSessionKeyDigestSigner: PolymarketOrderDigestSigning {
    func sign(digest: Data) async throws -> String {
        do {
            return try keyStore.sign(hash: digest, for: userWalletId)
        } catch {
            PolymarketLogger.error("Failed to sign the order digest with the session key", error: error)
            throw error
        }
    }
}
