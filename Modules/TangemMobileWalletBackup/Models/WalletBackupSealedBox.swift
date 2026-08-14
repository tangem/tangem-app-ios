//
//  WalletBackupSealedBox.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct WalletBackupSealedBox {
    let nonce: Data
    let ciphertext: Data
    let tag: Data
}
