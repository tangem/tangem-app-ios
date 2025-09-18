//
//  StoredCryptoAccount.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct StoredCryptoAccount: Codable, Equatable {
    typealias Token = StoredUserTokenList.Entry
    typealias Grouping = StoredUserTokenList.Grouping
    typealias Sorting = StoredUserTokenList.Sorting

    struct Icon: Codable, Equatable {
        let iconName: String
        let iconColor: String
    }

    let derivationIndex: Int
    /// Nil, if the account uses a localized name.
    let name: String?
    let icon: Icon
    let tokens: [Token]
    let grouping: Grouping
    let sorting: Sorting
}
