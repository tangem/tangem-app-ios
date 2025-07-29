//
//  HotSecureStorage.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

protocol HotSecureStorage {
    func get(_ account: String) throws -> Data?
    func store(_ object: Data, forKey account: String, overwrite: Bool) throws
    func delete(_ account: String) throws
}

extension HotSecureStorage {
    func store(_ object: Data, forKey account: String) throws {
        try store(object, forKey: account, overwrite: true)
    }
}

extension SecureStorage: HotSecureStorage {}
