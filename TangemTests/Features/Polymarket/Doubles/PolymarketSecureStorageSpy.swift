//
//  PolymarketSecureStorageSpy.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import Tangem

final class PolymarketSecureStorageSpy: PolymarketSecureStorage {
    var readError: (any Error)?
    var writeError: (any Error)?
    var deleteError: (any Error)?

    private(set) var items: [String: Data]
    private(set) var deletedAccounts: [String] = []

    init(items: [String: Data] = [:]) {
        self.items = items
    }

    func get(_ account: String) throws -> Data? {
        if let readError {
            throw readError
        }

        return items[account]
    }

    func store(_ object: Data, forKey account: String, overwrite: Bool) throws {
        if let writeError {
            throw writeError
        }

        items[account] = object
    }

    func delete(_ account: String) throws {
        if let deleteError {
            throw deleteError
        }

        deletedAccounts.append(account)
        items[account] = nil
    }
}
