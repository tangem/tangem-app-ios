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
    func canSignLongTransactions(network: BlockchainNetwork) -> Bool {
        guard NFCUtils.isPoorNfcQualityDevice else {
            return true
        }

        return !network.blockchain.hasLongTransactions
    }
}
