//
//  CommonCollectiblesSessionKeySigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemCollectibles
import TangemFoundation

final class CommonCollectiblesSessionKeySigner: CollectiblesSessionKeySigner {
    private let store: any CollectiblesSessionKeyWalletStore
    private let userWalletId: UserWalletId

    init(
        userWalletId: UserWalletId,
        store: any CollectiblesSessionKeyWalletStore = CommonCollectiblesSessionKeyWalletStore()
    ) {
        self.userWalletId = userWalletId
        self.store = store
    }

    func generateKey() async throws -> Data {
        try store.generateKey(for: userWalletId)
    }

    func publicKey() async throws -> Data? {
        try store.publicKey(for: userWalletId)
    }

    func signSpin(_ message: Data) async throws -> Data {
        try store.sign(message, for: userWalletId)
    }
}
