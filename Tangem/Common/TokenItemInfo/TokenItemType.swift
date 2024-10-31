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
    case `default`(WalletModel)
    case withoutDerivation(StoredUserTokenList.Entry)
}
