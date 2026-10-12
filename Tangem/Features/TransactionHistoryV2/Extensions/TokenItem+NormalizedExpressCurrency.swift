//
//  TokenItem+NormalizedExpressCurrency.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress

extension TokenItem {
    var normalizedExpressCurrency: ExpressCurrency {
        let currency = expressCurrency.asCurrency

        return ExpressCurrency(
            contractAddress: TransactionHistoryAddressNormalizer.normalize(currency.contractAddress, isEvm: blockchain.isEvm),
            network: currency.network
        )
    }
}
