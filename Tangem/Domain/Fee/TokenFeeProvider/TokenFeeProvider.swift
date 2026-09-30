//
//  TokenFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol TokenFeeProvider {
    var feeTokenItem: TokenItem { get }
    var hasMultipleFeeOptions: Bool { get }

    var balanceFeeTokenState: TokenBalanceType { get }
    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> { get }
    var formattedFeeTokenBalance: FormattedTokenBalanceType { get }

    var state: TokenFeeProviderState { get }
    var statePublisher: AnyPublisher<TokenFeeProviderState, Never> { get }

    var selectedTokenFee: TokenFee { get }
    var selectedTokenFeePublisher: AnyPublisher<TokenFee, Never> { get }

    var fees: [TokenFee] { get }
    var feesPublisher: AnyPublisher<[TokenFee], Never> { get }

    func select(feeOption: FeeOption)
    func setup(input: TokenFeeProviderInputData)

    @discardableResult
    func updateFees() -> Task<Void, Never>
}

// MARK: - TokenFeeProvider+

extension TokenFeeProvider {
    /// The fee-currency balance to judge fee / spend coverage against.
    ///
    /// A cached balance (`.loading(cached:)` / `.failure(cached:)`) still counts, and an unfunded account
    /// (`.empty(.noAccount)`) counts as zero; `nil` means no balance is known at all.
    /// Every "can the fee currency cover X" check should read this rather than `balanceFeeTokenState.loaded`
    /// (which drops cached values) or `.value` (which reports an unfunded account as unknown).
    var spendableFeeCurrencyBalance: Decimal? {
        balanceFeeTokenState.spendableValue
    }

    var fees: [TokenFee] {
        state.loadedFees.map { key, value in
            TokenFee(option: key, tokenItem: feeTokenItem, value: .success(value))
        }
    }

    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        statePublisher
            .map { state in
                state.loadedFees.map { key, value in
                    TokenFee(option: key, tokenItem: feeTokenItem, value: .success(value))
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - [TokenFeeProvider]+

extension [TokenFeeProvider] {
    var hasMultipleFeeProviders: Bool {
        filter { $0.state.isSupported }.unique(by: \.feeTokenItem).count > 1
    }

    subscript(feeTokenItem: TokenItem) -> TokenFeeProvider? {
        first { $0.feeTokenItem == feeTokenItem }
    }
}

enum TokenFeeProviderError: LocalizedError {
    case providerUnavailable
    case unsupportedByProvider
    case feeNotFound
    case notEnoughBalanceForFee(feeCurrencyBalance: Decimal)
    case notEnoughGaslessFeeBalance(feeCurrencyBalance: Decimal)

    var errorDescription: String? {
        switch self {
        case .providerUnavailable:
            return "Token fee provider is unavailable"
        case .unsupportedByProvider:
            return "Unsupported by provider"
        case .feeNotFound:
            return "Fee not found"
        case .notEnoughBalanceForFee:
            return "Not enough balance to cover the network fee"
        case .notEnoughGaslessFeeBalance:
            return "Not enough token balance to cover the gasless fee"
        }
    }
}
