//
//  File.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import LocalAuthentication
@testable import TangemHotSdk

enum MockedError: Error {
    case genericError
}

final class MockedSecureStorage: HotSecureStorage {
    private var storage: [String: Data] = [:]
    
    func store(_ object: Data, forKey account: String, overwrite: Bool) throws {
        storage[account] = object
    }
    
    func get(_ account: String) throws -> Data? {
        storage[account]
    }
    
    func delete(_ account: String) throws {
        guard storage[account] != nil else {
            throw MockedError.genericError
        }
        storage[account] = nil
    }
}

final class MockedSecureEnclaveService: HotSecureEnclaveService {
    func encryptData(_ data: Data, keyTag: String) throws -> Data {
        data
    }
    
    func decryptData(_ data: Data, keyTag: String) throws -> Data {
        data
    }
}
    
final class MockedBiometricsStorage: HotBiometricsStorage {
    private var storage: [String: Data] = [:]
    
    func get(_ account: String, context: LAContext?) throws -> Data? {
        storage[account]
    }
    
    func store(_ object: Data, forKey account: String, overwrite: Bool) throws {
        storage[account] = object
    }
    
    func delete(_ account: String) throws {
        guard storage[account] != nil else {
            throw MockedError.genericError
        }
        storage[account] = nil
    }
}
