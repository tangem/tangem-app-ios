//
//  UserTokensRepositoryUpdateRequest.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct UserTokensRepositoryUpdateRequest {
    let tokens: [StoredCryptoAccount.Token]
    let grouping: StoredCryptoAccount.Grouping
    let sorting: StoredCryptoAccount.Sorting
}
