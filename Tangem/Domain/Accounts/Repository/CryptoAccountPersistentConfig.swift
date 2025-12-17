//
//  CryptoAccountPersistentConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// An intermediate DTO for the repository. Basically, a `StoredCryptoAccount` model without tokens.
struct CryptoAccountPersistentConfig {
    let derivationIndex: Int
    /// Nil, if the account uses a localized name.
    let name: String?
    let iconName: String
    let iconColor: String
}

// MARK: - Auxiliary types

extension CryptoAccountPersistentConfig {
    struct TokenListAppearance {
        static let `default` = Self(
            // [REDACTED_TODO_COMMENT]
            grouping: StoredUserTokenList.empty.grouping,
            sorting: StoredUserTokenList.empty.sorting,
        )

        let grouping: StoredCryptoAccount.Grouping
        let sorting: StoredCryptoAccount.Sorting
    }
}

// MARK: - Convenience extensions

extension CryptoAccountPersistentConfig {
    /// A convenience initializer to create a config from an `AccountModel.Icon`.
    init(
        derivationIndex: Int,
        name: String?,
        icon: AccountModel.Icon
    ) {
        self.init(
            derivationIndex: derivationIndex,
            name: name,
            iconName: icon.name.rawValue,
            iconColor: icon.color.rawValue
        )
    }
}
