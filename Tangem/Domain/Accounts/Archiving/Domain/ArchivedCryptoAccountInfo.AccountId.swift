//
//  ArchivedCryptoAccountInfo.AccountId.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ArchivedCryptoAccountInfo {
    struct AccountId: Hashable, RawRepresentable {
        let rawValue: String
    }
}

// MARK: - AccountModelPersistentIdentifierConvertible protocol conformance

extension ArchivedCryptoAccountInfo.AccountId: AccountModelPersistentIdentifierConvertible {
    func toPersistentIdentifier() -> String {
        return rawValue
    }
}
