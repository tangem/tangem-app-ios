//
//  AccountOperationResult.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum AccountOperationResult {
    case none

    case redistributionHappened(pairs: [StoredCryptoAccountsTokensDistributor.DistributionPair])
}

extension AccountOperationResult {
    var redistributedAccountNames: (source: String, target: String)? {
        guard case .redistributionHappened(let pairs) = self else {
            return nil
        }

        for pair in pairs {
            guard case .account(let sourceName) = pair.source, let targetName = pair.toAccountName else {
                continue
            }

            return (sourceName ?? Localization.accountMainAccountTitle, targetName)
        }

        return nil
    }
}
