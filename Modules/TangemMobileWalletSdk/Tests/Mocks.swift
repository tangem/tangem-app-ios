//
//  Mocks.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import LocalAuthentication
@testable import TangemMobileWalletSdk
@testable import TangemSdk

enum MockedError: Error {
    case genericError
}

final class MockedSecureStorage: MobileWalletSecureStorage {
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

final class MockedSecureEnclaveService: MobileWalletSecureEnclaveService {
    func encryptData(_ data: Data, keyTag: String) throws -> Data {
        Data(data.reversed())
    }

    func decryptData(_ data: Data, keyTag: String) throws -> Data {
        Data(data.reversed())
    }

    func delete(tag: String) {}
}

final class MockedBiometricsSecureEnclaveService: MobileWalletBiometricsSecureEnclaveService {
    func encryptData(_ data: Data, keyTag: String, context: LAContext?) throws -> Data {
        Data(data.reversed())
    }

    func decryptData(_ data: Data, keyTag: String, context: LAContext) throws -> Data {
        Data(data.reversed())
    }

    func delete(tag: String) {}
}

final class MockedBiometricsStorage: MobileWalletBiometricsStorage {
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

    func hasValue(account: String) -> Bool {
        storage[account] != nil
    }
}
