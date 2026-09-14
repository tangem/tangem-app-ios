//
//  CollectiblesHotDelegateWalletStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Keeps the hot delegate key per real wallet and signs with it; reads never prompt the user.
protocol CollectiblesHotDelegateWalletStore {
    /// Creates a fresh key for the wallet, replacing whatever was held, and returns its public part.
    func generateKey(for userWalletId: UserWalletId) throws -> Data

    /// The held key's public part; `nil` when the device holds none.
    func publicKey(for userWalletId: UserWalletId) throws -> Data?

    func sign(_ message: Data, for userWalletId: UserWalletId) throws -> Data

    func deleteKey(for userWalletId: UserWalletId) throws
}
