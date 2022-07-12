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
    private let key: String
    private let defaultValue: T

    private let defaults: UserDefaults
    private let suiteName = AppEnvironment.current.suiteName

    var wrappedValue: T {
        get {
            defaults.object(forKey: key) as? T ?? defaultValue
        } set {
            defaults.set(newValue, forKey: key)
        }
    }

    init(type: StorageType, defaultValue: T) {
        key = type.rawValue
        self.defaultValue = defaultValue
        defaults = UserDefaults(suiteName: suiteName) ?? .standard
        migrateFromOldDefaultsIfNeeded()
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
