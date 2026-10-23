//
//  MnemonicUserWalletIdFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemSdk
import TangemMobileWalletSdk

struct MnemonicUserWalletIdFactory {
    private let curve = EllipticCurve.secp256k1

    func makeUserWalletId(mnemonic: Mnemonic, passphrase: String) throws -> UserWalletId {
        try PassphraseValidator.validate(passphrase: passphrase)

        let masterKey = try AnyMasterKeyFactory(mnemonic: mnemonic, passphrase: passphrase).makeMasterKey(for: curve)
        let publicKey = try masterKey.makePublicKey(for: curve).publicKey

        return UserWalletId(with: publicKey)
    }
}
