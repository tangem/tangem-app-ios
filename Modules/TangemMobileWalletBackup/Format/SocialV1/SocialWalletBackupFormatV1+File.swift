//
//  SocialWalletBackupFormatV1+File.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension SocialWalletBackupFormatV1 {
    struct File: Codable {
        let version: SocialWalletBackupFormatVersion
        let walletId: String
        let createdAt: String
        let crypto: Crypto
    }
}

// MARK: - Nested types

extension SocialWalletBackupFormatV1.File {
    struct Crypto: Codable {
        let cipher: String
        let cipherparams: CipherParams
        let ciphertext: Data
        let tag: Data
    }

    struct CipherParams: Codable {
        let nonce: Data
    }
}
