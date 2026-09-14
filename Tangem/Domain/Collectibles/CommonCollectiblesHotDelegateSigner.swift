//
//  CommonCollectiblesHotDelegateSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemCollectibles
import TangemFoundation

final class CommonCollectiblesHotDelegateSigner: CollectiblesHotDelegateSigner {
    private let store: any CollectiblesHotDelegateWalletStore
    private let userWalletId: UserWalletId

    init(
        userWalletId: UserWalletId,
        store: any CollectiblesHotDelegateWalletStore = CommonCollectiblesHotDelegateWalletStore()
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
