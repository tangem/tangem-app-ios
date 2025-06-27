//
//  DeeplinkNavigationAction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct DeeplinkNavigationAction: Equatable {
    let destination: DeeplinkDestination
    let params: DeeplinkParams

    func hasMinimumDataForHandling() -> Bool {
        switch destination {
        case .token, .staking:
            return params.tokenId != nil && params.networkId != nil
        case .tokenChart:
            return params.tokenId != nil
        default:
            return true
        }
    }

    enum DeeplinkDestination: String, Equatable {
        case token
        case referral
        case buy
        case sell
        case swap
        case markets
        case tokenChart = "token_chart"
        case staking
        case onramp
        case exchange
        case link
    }

    struct DeeplinkParams: Equatable {
        var kind: DeeplinkKind?
        var name: String?
        var tokenId: String?
        var networkId: String?
        var userWalletId: String?
        var derivationPath: String?
        var transactionId: String?
        var url: URL?

        static let empty = DeeplinkParams()

        enum DeeplinkKind: String {
            case promo
            case incomeTransaction = "income_transaction"
            case onrampStatusUpdate = "onramp_status_update"
            case swapStatusUpdate = "swap_status_update"
        }
    }
}
