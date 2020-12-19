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
	
	init(type: StorageType, defaultValue: T) {
		key = type.rawValue
		self.defaultValue = defaultValue
	}

    var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}
