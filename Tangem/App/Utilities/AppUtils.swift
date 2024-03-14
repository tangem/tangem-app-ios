//
//  AppUtils.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct AppUtils {
    func canSignLongTransactions(tokenItem: TokenItem) -> Bool {
        guard NFCUtils.isPoorNfcQualityDevice else {
            return true
        }

        return !tokenItem.hasLongTransactions
    }
}
