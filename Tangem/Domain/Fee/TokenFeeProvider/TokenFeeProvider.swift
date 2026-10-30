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
    var usageAvailabilityPublisher: AnyPublisher<FeeTokenUsageAvailability, Never> { get }

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
    var usageAvailabilityPublisher: AnyPublisher<FeeTokenUsageAvailability, Never> {
        .just(output: .available)
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

enum FeeTokenUsageAvailability: Equatable {
    case available
    case minimumBalanceRequired(amount: Decimal, tokenItem: TokenItem)

    var allowsFeePayment: Bool {
        switch self {
        case .available:
            return true
        case .minimumBalanceRequired:
            return false
        }
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
