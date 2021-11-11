//
//  Storage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@propertyWrapper
struct Storage<T> {
    let key: String
    let defaultValue: T
    
    let defaults: UserDefaults
    
    private let appGroupName = "group.com.tangem.Tangem"
    
	init(type: StorageType, defaultValue: T) {
		key = type.rawValue
		self.defaultValue = defaultValue
        defaults = UserDefaults(suiteName: appGroupName) ?? .standard
        migrateFromOldDefaultsIfNeeded()
	}

    var wrappedValue: T {
        get {
            defaults.object(forKey: key) as? T ?? defaultValue
        }
        set {
            defaults.set(newValue, forKey: key)
        }
    }
    
    private func migrateFromOldDefaultsIfNeeded() {
        let migrationKey = StorageType.isMigratedToNewUserDefaults.rawValue
        if defaults.bool(forKey: migrationKey) {
            return
        }
        let standardDefaults = UserDefaults.standard
        
        for key in standardDefaults.dictionaryRepresentation().keys {
            defaults.set(standardDefaults.dictionaryRepresentation()[key], forKey: key)
        }
        defaults.set(true, forKey: migrationKey)
        defaults.synchronize()
    }
}
