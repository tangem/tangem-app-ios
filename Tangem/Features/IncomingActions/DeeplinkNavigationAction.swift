//
//  DeeplinkNavigationAction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct DeeplinkNavigationAction: Equatable {
    // MARK: - Properties

    let destination: IncomingActionConstants.DeeplinkDestination
    let params: Params
    let deeplinkString: String
}

// MARK: - Types

extension DeeplinkNavigationAction {
    struct Params: Equatable {
        var type: IncomingActionConstants.DeeplinkType?
        var name: String?
        var tokenId: String?
        var networkId: String?
        var userWalletId: String?
        var derivationPath: String?
        var transactionId: String?
        var promoCode: String?
        var url: URL?
        var entry: String?
        var id: String?
        var refcode: String?
        var campaign: String?

        static let empty = Params()

        enum DeeplinkKind: String {
            case incomeTransaction = "income_transaction"
            case onrampStatusUpdate = "onramp_status_update"
            case swapStatusUpdate = "swap_status_update"
        }
    }
}
