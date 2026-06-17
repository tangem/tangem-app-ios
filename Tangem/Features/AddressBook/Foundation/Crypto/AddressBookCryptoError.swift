//
//  AddressBookCryptoError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum AddressBookCryptoError: Error {
    /// AES-GCM authentication tag mismatch — the ciphertext was tampered with, the key is wrong, or
    /// the cached blob is stale. The repository invalidates the cache and refetches.
    case authenticationFailed
    /// The signer returned a number of signatures that does not match the number of requested digests.
    case signatureCountMismatch
}
