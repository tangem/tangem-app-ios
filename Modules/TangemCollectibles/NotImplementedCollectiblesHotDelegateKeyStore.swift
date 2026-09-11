//
//  NotImplementedCollectiblesHotDelegateKeyStore.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation
public import TangemFoundation

// [REDACTED_TODO_COMMENT]
/// Reads answer `nil` so the wallet reconciles as `rekeyRequired`; writes throw so no caller goes on to name
/// a key on chain that this device cannot sign for.
public final class NotImplementedCollectiblesHotDelegateKeyStore: CollectiblesHotDelegateKeyStore {
    private struct NotImplementedError: Error {}

    public init() {}

    public func storePrivateKey(_ seed: Data, userWalletId: UserWalletId) throws {
        throw NotImplementedError()
    }

    public func privateKey(userWalletId: UserWalletId) throws -> Data? {
        nil
    }

    public func deletePrivateKey(userWalletId: UserWalletId) {}
}
