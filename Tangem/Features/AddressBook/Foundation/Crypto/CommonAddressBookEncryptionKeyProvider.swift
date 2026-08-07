//
//  CommonAddressBookEncryptionKeyProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import TangemFoundation

/// Derives the key deterministically from the wallet public key, reusing the same
/// `HMAC-SHA256(SHA256(seed), "TokensSymmetricKey")` derivation already used for token storage. The
/// result is identical for the same wallet, so it can equally be read from the existing
/// biometrics-protected keychain entry instead of being recomputed on demand.
struct CommonAddressBookEncryptionKeyProvider: AddressBookEncryptionKeyProviding {
    func encryptionKey(forWalletPublicKeySeed seed: Data) -> SymmetricKey {
        UserWalletEncryptionKey(userWalletIdSeed: seed).symmetricKey
    }
}
