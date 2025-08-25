//
//  File.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

enum BLSUtil {
    static func publicKey(
        entropy: Data,
        passphrase: String = "",
    ) throws -> ExtendedPublicKey {
        let factory = try AnyMasterKeyFactory(
            mnemonic: Mnemonic(entropyData: entropy),
            passphrase: passphrase
        )
        return try factory
            .makeMasterKey(for: .bls12381_G2_AUG)
            .makePublicKey(for: .bls12381_G2_AUG)
    }

    static func sign(hashes: [Data], entropy: Data, passphrase: String? = nil) throws -> [Data] {
        let factory = try AnyMasterKeyFactory(mnemonic: Mnemonic(entropyData: entropy), passphrase: passphrase ?? "")
        let masterKey = try factory.makeMasterKey(for: .bls12381_G2_AUG)

        return try hashes.map { hash in
            try masterKey.sign(hash, curve: .bls12381_G2_AUG)
        }
    }
}
