//
//  ScanResult.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

enum ScanResult: Equatable {
    case card(model: CardViewModel)
    case unsupported
    case notScannedYet
    
    var cardModel: CardViewModel? {
        switch self {
        case .card(let model):
            return model
        default:
            return nil
        }
    }
    
    var card: Card? {
        switch self {
        case .card(let model):
            return model.cardInfo.card
        default:
            return nil
        }
    }

    static func == (lhs: ScanResult, rhs: ScanResult) -> Bool {
        switch (lhs, rhs) {
        case (.card, .card): return true
        case (.unsupported, .unsupported): return true
        case (.notScannedYet, .notScannedYet): return true
        default:
            return false
        }
    }
}
