//
//  AnalyticsSessionContextScope.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum AnalyticsSessionContextScope {
    case common
    case userWallet(UserWalletId)
}
