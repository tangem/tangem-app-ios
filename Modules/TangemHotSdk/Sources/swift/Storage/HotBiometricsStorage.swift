//
//  HotBiometricsStorage.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import LocalAuthentication
import TangemSdk

protocol HotBiometricsStorage {
    func get(_ account: String, context: LAContext?) throws -> Data?
    func store(_ object: Data, forKey account: String, overwrite: Bool) throws
    func delete(_ account : String) throws
}

extension HotBiometricsStorage {
    func store(_ object: Data, forKey account: String) throws {
        try store(object, forKey: account, overwrite: true)
    }
}

extension BiometricsStorage: HotBiometricsStorage {}
