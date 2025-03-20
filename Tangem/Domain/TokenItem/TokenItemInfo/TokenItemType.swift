//
//  TokenItemType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum TokenItemType: Equatable {
    /// `Default` means `coin/token with derivation`,  unlike `withoutDerivation` case.
    case `default`(any WalletModel)
    case withoutDerivation(StoredUserTokenList.Entry)
}

extension TokenItemType {
    static func == (lhs: TokenItemType, rhs: TokenItemType) -> Bool {
        switch (lhs, rhs) {
        case (let .default(lhsModel), .default(let rhsModel)):
            return lhsModel.id == rhsModel.id
        case (let .withoutDerivation(lhsEntry), .withoutDerivation(let rhsEntry)):
            return lhsEntry == rhsEntry
        default:
            return false
        }
    }
}
