//
//  KeychainRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data

/// Inserts, updates, retrieves, and deletes a single opaque blob of `Data` in the Keychain.
protocol KeychainRepository: Sendable {
    /// Adds `data` as a new item.
    /// - Parameter data: The value to store.
    /// - Throws: ``KeychainRepositoryError/duplicateItem`` if one already exists or
    /// ``KeychainRepositoryError/insertFailed(status:)`` if insert failed for some other reason.
    func insert(_ data: Data) async throws(KeychainRepositoryError)

    /// - Returns: The currently stored item, or `nil` if none exists.
    /// - Throws: ``KeychainRepositoryError/itemCorrupted`` if a stored item was found but isn't `Data`,
    /// or ``KeychainRepositoryError/retrieveFailed(status:)`` if the lookup failed for some other reason.
    func retrieve() async throws(KeychainRepositoryError) -> Data?

    /// Replaces the value of an existing item with `data`.
    /// - Parameter data: The new value to store.
    /// - Throws: ``KeychainRepositoryError/updateFailed(status:)`` if nothing is stored to update,
    /// or if the update failed for some other reason.
    func update(_ data: Data) async throws(KeychainRepositoryError)

    /// Removes any stored item. A no-op if none is stored.
    /// - Throws: ``KeychainRepositoryError/deleteFailed(status:)`` if the removal failed.
    func delete() async throws(KeychainRepositoryError)
}

extension KeychainRepository {
    /// Ensures `data` is stored, replacing whatever was there before.
    ///
    /// Prefers ``update(_:)`` over deleting and re-inserting: an update never leaves a window where the item doesn't exist,
    /// and it preserves the item's Keychain persistent reference.
    func updateOrInsert(_ data: Data) async throws(KeychainRepositoryError) {
        do {
            try await insert(data)
        } catch KeychainRepositoryError.duplicateItem {
            try await update(data)
        }
    }
}
