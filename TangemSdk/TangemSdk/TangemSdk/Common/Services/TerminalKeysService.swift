//
//  TerminalKeysService.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Service for manage keypair, used for Linked Terminal feature. Can be disabled by legacyMode or manually
public class TerminalKeysService {
    public static let enabled = true
    private let secureStorageService: SecureStorageService
    
    init(secureStorageService: SecureStorageService) {
        self.secureStorageService = secureStorageService
    }
    
    /// Retrieve generated keys from keychain if they exist. Generate new and store in Keychain otherwise
    func getKeys() -> KeyPair? {
        guard TerminalKeysService.enabled else {
            return nil
        }
        
        guard !LegacyModeService.useLegacyMode else {
            return nil
        }
        
        if let privateKey = secureStorageService.get(key: StorageKey.terminalPrivateKey.rawValue) as? Data,
            let publicKey = secureStorageService.get(key: StorageKey.terminalPublicKey.rawValue) as? Data {
            return KeyPair(privateKey: privateKey, publicKey: publicKey)
        }
        
        if let newKeys = CryptoUtils.generateKeyPair() {
            secureStorageService.store(object: newKeys.privateKey, key: StorageKey.terminalPrivateKey.rawValue)
            secureStorageService.store(object: newKeys.publicKey, key: StorageKey.terminalPublicKey.rawValue)
            return newKeys
        }
        
        return nil
    }
}
