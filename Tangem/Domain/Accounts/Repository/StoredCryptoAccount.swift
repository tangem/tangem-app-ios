//
//  StoredCryptoAccount.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct StoredCryptoAccount: Codable {
    typealias TokenList = StoredUserTokenList

    struct Icon: Codable {
        let iconName: String
        let iconColor: String
    }

    let derivationIndex: Int
    let name: String
    let icon: Icon
    let tokenList: TokenList
}
