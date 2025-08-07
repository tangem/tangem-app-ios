//
//  UserWalletModelUnlocker.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

protocol UserWalletModelUnlocker {
    /// For unprotected mobile wallets
    var canUnlockAutomatically: Bool { get }

    /// For mobile wallets
    var canShowUnlockUIAutomatically: Bool { get }

    func unlock() async -> UserWalletModelUnlockerResult
}

enum UserWalletModelUnlockerResult {
    case success(userWalletId: UserWalletId, encryptionKey: UserWalletEncryptionKey)
    case error(Error)
    case bioSelected
    case userWalletNeedsToDelete
    case scanTroubleshooting
}
