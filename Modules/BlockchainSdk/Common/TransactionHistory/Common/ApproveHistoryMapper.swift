//
//  ApproveHistoryMapper.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import TangemFoundation

/// Recovers what an ERC-20 `approve` granted from its calldata. Shared by the history mappers, which differ only in
/// how much they know about the approved token: a provider that lists the address's tokens can label and scale the
/// allowance, one that doesn't can still report the allowances that need neither.
enum ApproveHistoryMapper {
    /// - Parameters:
    ///   - symbol: symbol of the approved token, when the provider knows it.
    ///   - decimals: decimals of the approved token. Without them a limited allowance is just a raw integer, so it is
    ///     reported as `nil` — leaving the record a plain contract call rather than an approve missing its amount.
    static func approve(calldata: String?, symbol: String?, decimals: Int?) -> TransactionRecord.TransactionType.Approve? {
        guard let calldata, let method = ApproveERC20TokenMethod(calldata: calldata) else {
            return nil
        }

        guard !method.isUnlimited else {
            return .init(spender: method.spender, symbol: symbol, allowance: .unlimited)
        }

        guard method.amount > 0 else {
            return .init(spender: method.spender, symbol: symbol, allowance: .revoked)
        }

        // The same uint256-to-amount conversion an ERC-20 `balanceOf` goes through: it scales by the token's
        // decimals and reports a value that doesn't fit as `nil`, rather than as a silently rounded one.
        guard let decimals, let amount = EthereumUtils.parseEthereumDecimal(method.amount.serialize().hex(), decimalsCount: decimals) else {
            return nil
        }

        return .init(spender: method.spender, symbol: symbol, allowance: .limited(amount))
    }
}
