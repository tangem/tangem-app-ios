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

        return tokenItem.canBeSignedOnLegacyDevice
    }
}

fileprivate extension TokenItem {
    // We can't sign transactions at legacy devices fot these blockchains
    var canBeSignedOnLegacyDevice: Bool {
        switch blockchain {
        case .solana:
            return isToken ? false : true
        case .chia:
            return false
        default:
            return true
        }
    }
}
