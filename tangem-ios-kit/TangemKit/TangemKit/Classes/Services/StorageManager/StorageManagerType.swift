//
//  StorageManagerType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

 public protocol StorageManagerType: NSObject {
    func set(_ stringArray: [String], forKey key: StorageKey)
    func stringArray(forKey key: StorageKey) -> [String]?
}
