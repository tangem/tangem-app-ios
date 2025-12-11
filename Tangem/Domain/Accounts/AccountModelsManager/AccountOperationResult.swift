//
//  AccountOperationResult.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum AccountOperationResult {
    case none

    case redistributionHappened(pairs: [StoredCryptoAccountsTokensDistributor.DistributionPair])
}
