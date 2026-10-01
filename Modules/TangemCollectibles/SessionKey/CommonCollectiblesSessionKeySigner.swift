//
//  CommonCollectiblesSessionKeySigner.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation
public import TangemFoundation

public final class CommonCollectiblesSessionKeySigner: CollectiblesSessionKeySigner {
    private let store: any CollectiblesSessionKeyWalletStore
    private let userWalletId: UserWalletId

    public init(
        userWalletId: UserWalletId,
        store: any CollectiblesSessionKeyWalletStore = CommonCollectiblesSessionKeyWalletStore()
    ) {
        self.userWalletId = userWalletId
        self.store = store
    }

    public func generateKey() async throws -> Data {
        try store.generateKey(for: userWalletId)
    }

    public func publicKey() async throws -> Data? {
        try store.publicKey(for: userWalletId)
    }

    public func signSpin(_ message: Data) async throws -> Data {
        try store.sign(message, for: userWalletId)
    }
}
