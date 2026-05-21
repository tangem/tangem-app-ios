//
//  SendYieldModuleHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol SendYieldModuleHelper: YieldModuleTransactionHelper {
    func refreshVersionAfterUpgrade() async throws
    func isUpgradeWrapped(_ data: ExpressTransactionData) -> Bool
}
