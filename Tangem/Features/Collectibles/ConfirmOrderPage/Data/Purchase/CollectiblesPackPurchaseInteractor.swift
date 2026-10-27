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
        isTurboModeOn: Bool,
        onStep: @escaping (CollectiblesPackPurchaseStep) -> Void
    ) async throws -> CollectiblesPackPurchaseResult
}

enum CollectiblesPackPurchaseResult {
    case wonCard(CollectiblesWonCard)
    case autoSold(amount: Decimal?)
}

enum CollectiblesPackPurchaseStep {
    case generating
    case confirming
    case opening
}

enum CollectiblesPackPurchaseError: Error {
    case accountNotReady
    case lowInventory
    case invalidPrice
    case paymentFailed(CollectiblesPurchaseStatus)
    case paymentTimedOut
    case packUnopened
    case openFailed
    case prizeNotDelivered
    case anotherPurchaseInProgress
}
