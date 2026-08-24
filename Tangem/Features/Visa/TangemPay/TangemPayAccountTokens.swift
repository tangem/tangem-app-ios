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
    /// Funding candidates in a stable priority — the canonical token first, then by withdrawable
    /// funds, ties by network and contract. The BFF response order carries no meaning.
    var fundingPriorityOrdered: [TangemPayAccountToken] {
        sorted { lhs, rhs in
            if lhs.isCanonical != rhs.isCanonical {
                return lhs.isCanonical
            }

            let lhsFunds = lhs.availableForWithdrawal ?? 0
            let rhsFunds = rhs.availableForWithdrawal ?? 0
            guard lhsFunds == rhsFunds else {
                return lhsFunds > rhsFunds
            }

            return lhs.assetIdentity < rhs.assetIdentity
        }
    }

    /// The withdraw endpoint carries only an amount and a destination — the asset is implicitly
    /// USDC on Polygon. Until the API can express a token and a network, no other entry may start
    /// a withdraw, no matter how funded it is.
    var withdrawStartingPoint: TangemPayAccountToken? {
        filter(\.isCanonical).max { ($0.availableForWithdrawal ?? 0) < ($1.availableForWithdrawal ?? 0) }
    }
}

private extension TangemPayAccountToken {
    /// USDC on Polygon — the one asset the whole Tangem Pay API surface speaks natively.
    var isCanonical: Bool {
        tokenItem.blockchain == TangemPayUtilities.blockchain
            && tokenItem.token == TangemPayUtilities.usdcTokenItem.token
    }

    var assetIdentity: String {
        "\(tokenItem.networkId) \(tokenItem.contractAddress?.lowercased() ?? "")"
    }
}
