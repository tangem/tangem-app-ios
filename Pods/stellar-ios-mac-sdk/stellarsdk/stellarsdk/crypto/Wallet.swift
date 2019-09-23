//
//  Wallet.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Generates Mnemonic with corresponding Stellar Keypair.
public final class Wallet {
    
    /// Generates a 12 word Mnemonic.
    public static func generate12WordMnemonic(language: WordList = .english) -> String {
        return Mnemonic.create(strength: .normal, language: language)
    }
    
    /// Generates a 24 word Mnemonic.
    public static func generate24WordMnemonic(language: WordList = .english) -> String {
        return Mnemonic.create(strength: .high, language: language)
    }
    
    /// Creates a new KeyPair from the given mnemonic and index.
    ///
    /// - Parameter mnemonic: The mnemonic string.
    /// - Parameter passphrase: The passphrase.
    /// - Parameter index: The index of the wallet to generate.
    ///
    public static func createKeyPair(mnemonic: String, passphrase: String?, index: Int) throws -> KeyPair {
        var bip39Seed: Data!
        
        if let passphraseValue = passphrase, !passphraseValue.isEmpty {
            bip39Seed = Mnemonic.createSeed(mnemonic: mnemonic, withPassphrase: passphraseValue)
        } else {
            bip39Seed = Mnemonic.createSeed(mnemonic: mnemonic)
        }
        
        let masterPrivateKey = Ed25519Derivation(seed: bip39Seed)
        let purpose = masterPrivateKey.derived(at: 44)
        let coinType = purpose.derived(at: 148)
        let account = coinType.derived(at: UInt32(index))
        let stellarSeed = try! Seed(bytes: account.raw.bytes)
        let keyPair = KeyPair.init(seed: stellarSeed)
        
        return keyPair
    }
}
