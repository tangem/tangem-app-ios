//
//  TangemPayAccountTokens.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import TangemFoundation
import TangemPay

/// A token the payment account holds under the hood — a funding (transfer) target and a
/// withdrawal source. One per token per network the account is issued on.
struct TangemPayAccountToken: Equatable {
    let tokenItem: TokenItem
    let depositAddress: String
    let availableForWithdrawal: Decimal?
    let chainId: Int?
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

    /// Ties resolve towards the canonical token.
    var withdrawStartingPoint: TangemPayAccountToken? {
        filter(\.isWithdrawEligible).sorted { lhs, rhs in
            let lhsFunds = lhs.availableForWithdrawal ?? 0
            let rhsFunds = rhs.availableForWithdrawal ?? 0
            guard lhsFunds == rhsFunds else {
                return lhsFunds > rhsFunds
            }

            if lhs.isCanonical != rhs.isCanonical {
                return lhs.isCanonical
            }

            return lhs.assetIdentity < rhs.assetIdentity
        }.first
    }
}

enum TangemPayWithdrawEligibility: Equatable {
    /// The BFF picks the network; only the account-wide stand-in is withdrawn this way.
    case untargeted
    case targeted(TangemPayWithdrawTarget)
    /// The token can't be addressed by the withdraw API.
    case ineligible
}

extension TangemPayAccountToken {
    var withdrawEligibility: TangemPayWithdrawEligibility {
        guard let chainId else {
            return isCanonical ? .untargeted : .ineligible
        }

        guard let contractAddress = tokenItem.contractAddress?.nilIfEmpty else {
            return .ineligible
        }

        return .targeted(TangemPayWithdrawTarget(
            chainId: chainId,
            tokenContractAddress: contractAddress
        ))
    }

    var isWithdrawEligible: Bool {
        withdrawEligibility != .ineligible
    }

    var isAccountWide: Bool {
        chainId == nil
    }
}

extension TangemPayWithdrawEligibility {
    func resolveDispatchTarget() throws -> TangemPayWithdrawTarget? {
        switch self {
        case .targeted(let target):
            return target
        case .untargeted:
            return nil
        case .ineligible:
            throw Error.tokenNotWithdrawable
        }
    }

    enum Error: LocalizedError {
        case tokenNotWithdrawable
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
