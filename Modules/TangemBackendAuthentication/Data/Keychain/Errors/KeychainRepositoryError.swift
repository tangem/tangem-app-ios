//
//  KeychainRepositoryError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import typealias Darwin.MacTypes.OSStatus

/// The specific reason ``KeychainRepository`` failed to insert, update, retrieve, or delete an item.
public enum KeychainRepositoryError: Error, Equatable, Sendable {
    /// A Keychain item was found for the expected service/account, but it isn't `Foundation.Data` as expected.
    case itemCorrupted

    /// ``KeychainRepository/insert(_:)`` found an item already stored under this service/account.
    case duplicateItem

    /// Inserting a new item into the Keychain failed.
    case insertFailed(status: OSStatus)

    /// Updating the existing item in the Keychain failed.
    case updateFailed(status: OSStatus)

    /// Looking up the stored item in the Keychain failed.
    ///
    /// - Invariant: Never `errSecItemNotFound` — that outcome means no item exists yet, not a failure.
    case retrieveFailed(status: OSStatus)

    /// Removing the item from the Keychain failed.
    ///
    /// - Invariant: Never `errSecItemNotFound` — that outcome means nothing was stored, not a failure.
    case deleteFailed(status: OSStatus)
}
