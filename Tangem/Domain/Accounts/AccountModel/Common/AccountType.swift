//
//  AccountType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Tells apart the kinds of account that share the crypto account storage, identity and screens.
/// - Warning: Raw values are both what the endpoint reports and what a stored record keeps, so an existing case cannot
/// change its value without agreeing it with the backend and migrating what is already stored.
enum AccountType: String, Codable, Equatable {
    case crypto
    case joint
}

// MARK: - Decodable protocol conformance

extension AccountType {
    /// - Warning: A value that cannot be read is a crypto account rather than an error. A stored account record holds
    /// this type, the whole list of records is decoded at once, and a failed read of that list is taken for an empty
    /// storage — which sends a wallet that has accounts through the legacy migration.
    init(from decoder: any Decoder) throws {
        let rawValue = try? decoder.singleValueContainer().decode(String.self)

        self = rawValue.flatMap(AccountType.init(rawValue:)) ?? .crypto
    }
}
