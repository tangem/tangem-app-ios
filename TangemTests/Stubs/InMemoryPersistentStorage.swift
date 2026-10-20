//
//  InMemoryPersistentStorage.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
@testable import Tangem

/// Round-trips through `Codable` like the real storage does, so the suites also cover encoding of the cache entry.
final class InMemoryPersistentStorage: PersistentStorageProtocol {
    var storeError: (Error & Sendable)? {
        get { storeErrorState { $0 } }
        set { storeErrorState { $0 = newValue } }
    }

    var storeCalls: Int { writes.withLock { $0 } }

    private let storeErrorState = OSAllocatedUnfairLock<(Error & Sendable)?>(initialState: nil)
    private let state = OSAllocatedUnfairLock(initialState: [String: Data]())
    private let writes = OSAllocatedUnfairLock(initialState: 0)

    func value<T: Decodable>(for key: PersistentStorageKey) throws -> T? {
        guard let data = state.withLock({ $0[key.path] }) else {
            return nil
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    func store(value: some Encodable, for key: PersistentStorageKey) throws {
        if let storeError {
            throw storeError
        }

        let data = try JSONEncoder().encode(value)
        state.withLock { $0[key.path] = data }
        writes.withLock { $0 += 1 }
    }

    func remove(for key: PersistentStorageKey) throws {
        state.withLock { $0[key.path] = nil }
    }

    var paths: [String] {
        state.withLock { Array($0.keys) }
    }

    func overwrite(path: String, json: String) {
        state.withLock { $0[path] = Data(json.utf8) }
    }
}
