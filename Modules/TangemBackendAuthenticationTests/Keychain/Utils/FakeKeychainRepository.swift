//
//  FakeKeychainRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
private import os.lock
@testable import TangemBackendAuthentication

final class FakeKeychainRepository: KeychainRepository {
    private let storedData = OSAllocatedUnfairLock<Data?>(initialState: nil)

    func insert(_ data: Data) throws(KeychainRepositoryError) {
        // [REDACTED_USERNAME], this mimics real Keychain behavior for the attempt to insert a duplicate item twice
        guard storedData.withLock({ $0 }) == nil else {
            throw KeychainRepositoryError.duplicateItem
        }

        storedData.withLock { $0 = data }
    }

    func update(_ data: Data) throws(KeychainRepositoryError) {
        storedData.withLock { $0 = data }
    }

    func retrieve() throws(KeychainRepositoryError) -> Data? {
        storedData.withLock { $0 }
    }

    func delete() throws(KeychainRepositoryError) {
        storedData.withLock { $0 = nil }
    }
}
