//
//  Storage.swift
//  Tangem Tap
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
    
	init(type: StorageType, defaultValue: T) {
		key = type.rawValue
		self.defaultValue = defaultValue
        defaults = UserDefaults(suiteName: "group.com.tangem.Tangem") ?? .standard
	}

    var wrappedValue: T {
        get {
            defaults.object(forKey: key) as? T ?? defaultValue
        }
        set {
            defaults.set(newValue, forKey: key)
        }
    }
}
