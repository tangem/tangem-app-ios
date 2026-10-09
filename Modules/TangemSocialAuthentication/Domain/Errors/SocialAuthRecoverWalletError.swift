//
//  SocialAuthRecoverWalletError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum SocialAuthRecoverWalletError: Error {
    /// The recovery key envelope failed to decode or decrypt.
    case decryptionFailed
    /// The cloud storage holds no social backup for the account.
    case backupNotFound
}
