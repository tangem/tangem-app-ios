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
/// allowance, one that doesn't leaves a limited allowance unscaled for the app to finish once it resolves the token.
enum ApproveHistoryMapper {
    /// - Parameters:
    ///   - symbol: symbol of the approved token, when the provider knows it.
    ///   - decimals: decimals of the approved token. Without them a limited allowance is just a raw integer, so it is
    ///     reported as `.unscaled`.
    static func approve(calldata: String?, symbol: String?, decimals: Int?) -> TransactionRecord.TransactionType.Approve? {
        guard let calldata, let method = ApproveERC20TokenMethod(calldata: calldata) else {
            return nil
        }

        return approve(spender: method.spender, amount: method.amount, symbol: symbol, decimals: decimals)
    }

    static func approve(spender: String, amount: BigUInt, symbol: String?, decimals: Int?) -> TransactionRecord.TransactionType.Approve {
        guard amount != .maxUInt256 else {
            return .init(spender: spender, symbol: symbol, allowance: .unlimited)
        }

        guard amount > 0 else {
            return .init(spender: spender, symbol: symbol, allowance: .revoked)
        }

        guard let decimals, let scaledAmount = scale(amount, decimals: decimals) else {
            return .init(spender: spender, symbol: symbol, allowance: .unscaled(amount))
        }

        return .init(spender: spender, symbol: symbol, allowance: .limited(scaledAmount))
    }

    static func scale(_ amount: BigUInt, decimals: Int) -> Decimal? {
        EthereumUtils.parseEthereumDecimal(amount.serialize().hex(), decimalsCount: decimals)
    }
}

public extension TransactionRecord.TransactionType.Approve {
    func resolving(symbol: String, decimals: Int) -> Self {
        let resolvedAllowance: Allowance = switch allowance {
        case .unscaled(let amount):
            ApproveHistoryMapper.scale(amount, decimals: decimals).map { .limited($0) } ?? allowance
        case .unlimited, .revoked, .limited:
            allowance
        }

        return .init(spender: spender, symbol: self.symbol ?? symbol, allowance: resolvedAllowance)
    }
}
