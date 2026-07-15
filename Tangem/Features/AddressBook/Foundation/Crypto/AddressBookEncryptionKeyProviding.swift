//
//  AddressBookEncryptionKeyProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

/// Derives the symmetric key used to encrypt a wallet's address book.
protocol AddressBookEncryptionKeyProviding {
    func encryptionKey(forWalletPublicKeySeed seed: Data) -> SymmetricKey
}
