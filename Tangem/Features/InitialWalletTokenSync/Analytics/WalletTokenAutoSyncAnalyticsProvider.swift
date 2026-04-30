//
//  WalletTokenAutoSyncAnalyticsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol WalletTokenAutoSyncAnalyticsProvider {
    func logInitialTokenSyncStarted(userWalletId: UserWalletId)
    func logInitialTokenSyncCompleted(userWalletId: UserWalletId)
}
