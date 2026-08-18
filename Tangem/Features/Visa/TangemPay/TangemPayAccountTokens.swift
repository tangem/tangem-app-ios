//
//  TangemPayAccountTokens.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import TangemPay

/// A token the payment account holds under the hood — a funding (transfer) target and a
/// withdrawal source. One per token per network the account is issued on.
struct TangemPayAccountToken: Equatable {
    let tokenItem: TokenItem
    let depositAddress: String
    let availableForWithdrawal: Decimal?
}

extension [TangemPayAccountToken] {
    /// The withdraw endpoint carries only an amount and a destination — the asset is implicitly
    /// USDC on Polygon. Until the API can express a token and a network, no other entry may start
    /// a withdraw, no matter how funded it is.
    var withdrawStartingPoint: TangemPayAccountToken? {
        withdrawAPICompatible.max { ($0.availableForWithdrawal ?? 0) < ($1.availableForWithdrawal ?? 0) }
    }

    private var withdrawAPICompatible: [TangemPayAccountToken] {
        filter {
            $0.tokenItem.blockchain == TangemPayUtilities.blockchain
                && $0.tokenItem.token == TangemPayUtilities.usdcTokenItem.token
        }
    }
}
