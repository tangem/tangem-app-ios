//
//  CollectiblesDepositReceivingRestrictionsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CollectiblesDepositReceivingRestrictionsProvider: ReceivingRestrictionsProvider {
    let userWalletInfo: UserWalletInfo

    var isRestrictionKnown: Bool { true }

    func restriction(expectAmount: Decimal) async throws -> ReceivedRestriction? {
        guard userWalletInfo.backupState.isValid else {
            return .incompleteBackup(userWalletInfo)
        }

        return nil
    }
}
