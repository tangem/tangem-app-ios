//
//  StorageManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import KeychainSwift

class SecureStorageManager: NSObject {
    private func get(key: String) -> Any? {
        let keychain = KeychainSwift()
        if let data = keychain.getData(key) {
            return NSKeyedUnarchiver.unarchiveObject(with: data)
        }
        return nil
    }
    
    private func store(object: Any, key: String) {
        let data = NSKeyedArchiver.archivedData(withRootObject: object)
        let keychain = KeychainSwift()
        keychain.synchronizable = false
        keychain.set(data, forKey: key, withAccess: .accessibleWhenUnlocked)
    }
}

extension SecureStorageManager: StorageManagerType {
    func set(_ stringArray: [String], forKey key: StorageKey) {
        store(object: stringArray, key: key.rawValue)
    }
    
    func stringArray(forKey key: StorageKey) -> [String]? {
        return get(key: key.rawValue) as? [String]
    }
}
