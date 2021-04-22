//
//  Mnemonic.swift
//  WalletKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 yuzushioh. All rights reserved.
//

// https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki

import Foundation

public final class Mnemonic {
    public enum Strength: Int {
        case normal = 128
        case high = 256
    }
    
    public static func createSeed(mnemonic: String, withPassphrase passphrase: String = "") -> Data {
        guard let password = mnemonic.decomposedStringWithCompatibilityMapping.data(using: .utf8) else {
            fatalError("Nomalizing password failed in \(self)")
        }
        
        guard let salt = ("mnemonic" + passphrase).decomposedStringWithCompatibilityMapping.data(using: .utf8) else {
            fatalError("Nomalizing salt failed in \(self)")
        }
        
        return HDCrypto.PBKDF2SHA512(password: password.bytes, salt: salt.bytes)
    }
}


