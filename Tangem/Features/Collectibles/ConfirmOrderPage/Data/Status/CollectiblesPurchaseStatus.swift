//
//  CollectiblesPurchaseStatus.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum CollectiblesPurchaseStatus: Equatable {
    case created
    case waitingTxHash
    case purchaseTxHash
    case waitingForPayment
    case expired
    case packPurchased
    case packOpeningError
    case refunded
    case autoBuybacked
    case packOpened
    case nftReceived
    case manuallyBuybacked
    case paused
    case unknown(String)
}
