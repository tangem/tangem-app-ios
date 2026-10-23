//
//  Collectibles+UniversalError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

// `Subsystems` (`000` to `008` and `017` live in the TangemCollectibles module):
// `009` - CollectiblesAPIService.Error
// `010` - CollectiblesPackPurchaseError
// `011` - CollectiblesPurchaseGenerationError
// `012` - CollectiblesBuybackSaleError
// `013` - RemoteCollectiblesBuybackInteractor.SigningFailure
// `014` - CollectiblesDepositSendingUnsupportedError
// `015` - CommonCollectiblesColdKeyInteractor.ColdKeyError
// `016` - CommonCollectiblesDevnetActions.DevnetActionError

extension CollectiblesAPIService.Error: UniversalError {
    var errorCode: Int {
        switch self {
        case .http: 114009000
        case .decoding: 114009001
        case .connection: 114009002
        }
    }
}

extension CollectiblesPackPurchaseError: UniversalError {
    var errorCode: Int {
        switch self {
        case .accountNotReady: 114010000
        case .lowInventory: 114010001
        case .invalidPrice: 114010002
        case .paymentFailed: 114010003
        case .paymentTimedOut: 114010004
        case .packUnopened: 114010005
        case .openFailed: 114010006
        case .prizeNotDelivered: 114010007
        case .anotherPurchaseInProgress: 114010008
        }
    }
}

extension CollectiblesPurchaseGenerationError: UniversalError {
    var errorCode: Int {
        switch self {
        case .lowInventory: 114011000
        }
    }
}

extension CollectiblesBuybackSaleError: UniversalError {
    var errorCode: Int {
        switch self {
        case .accountNotReady: 114012000
        case .failed: 114012001
        case .notConfirmed: 114012002
        }
    }
}

extension RemoteCollectiblesBuybackInteractor.SigningFailure: UniversalError {
    var errorCode: Int {
        switch self {
        case .transactionTooLarge: 114013000
        }
    }
}

extension CollectiblesDepositSendingUnsupportedError: UniversalError {
    var errorCode: Int {
        switch self {
        case .sendingUnsupported: 114014000
        }
    }
}

extension CommonCollectiblesColdKeyInteractor.ColdKeyError: UniversalError {
    var errorCode: Int {
        switch self {
        case .coldOwnerMismatch: 114015000
        }
    }
}

extension CommonCollectiblesDevnetActions.DevnetActionError: UniversalError {
    var errorCode: Int {
        switch self {
        case .coldKeyNotDerived: 114016000
        case .vaultNotReady: 114016001
        }
    }
}
