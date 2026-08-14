//
//  SecureErase.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Zeroes the buffer in place; `memset_s` cannot be optimized away. Best effort by nature:
/// it covers this instance only, not copies made by COW, coders or the crypto layer.
func secureErase(data: inout Data) {
    _ = data.withUnsafeMutableBytes { bytes in
        memset_s(bytes.baseAddress, bytes.count, 0, bytes.count)
    }
}
