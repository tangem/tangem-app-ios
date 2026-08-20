//
//  WalletBackupEncodingError.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum WalletBackupEncodingError: Error {
    case encodingFailed(Error)
    /// Carries no underlying error on purpose: encoder errors can embed fragments
    /// of the input, which here is the plaintext mnemonic.
    case payloadEncodingFailed
}
