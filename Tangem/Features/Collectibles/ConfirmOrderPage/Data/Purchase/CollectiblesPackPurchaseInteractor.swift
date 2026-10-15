//
//  CollectiblesPackPurchaseInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemCollectibles

@MainActor
protocol CollectiblesPackPurchaseInteractor: AnyObject {
    func hasUnfinishedPurchase(machineID: String) -> Bool

    func purchase(
        machineID: String,
        price: Decimal,
        platformFee: Decimal,
        turboMode: CollectiblesTurboMode,
        onStep: @escaping (CollectiblesPackPurchaseStep) -> Void
    ) async throws -> CollectiblesWonCard
}

enum CollectiblesPackPurchaseStep {
    case generating
    case confirming
    case opening
}

enum CollectiblesPackPurchaseError: Error {
    case accountNotReady
    case invalidPrice
    case paymentFailed(CollectiblesPurchaseStatus)
    case paymentTimedOut
    case openFailed
    case prizeNotDelivered
    case anotherPurchaseInProgress
}
