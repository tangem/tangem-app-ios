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
    var balanceFeeTokenState: TokenBalanceType { get }
    var formattedFeeTokenBalance: FormattedTokenBalanceType { get }
    var hasMultipleFeeOptions: Bool { get }

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
    var hasMultipleFeeProviders: Bool { unique(by: \.feeTokenItem).count > 1 }
}

// MARK: - TokenFeeProvider+Init

extension TokenFeeProvider where Self == EmptyTokenFeeProvider {
    static func empty(feeTokenItem: TokenItem) -> Self {
        EmptyTokenFeeProvider(feeTokenItem: feeTokenItem)
    }
}

extension TokenFeeProvider where Self == CommonTokenFeeProvider {
    static func common(
        feeTokenItem: TokenItem,
        supportingOptions: TokenFeeProviderSupportingOptions,
        availableTokenBalanceProvider: TokenBalanceProvider,
        tokenFeeLoader: any TokenFeeLoader,
        customFeeProvider: (any CustomFeeProvider)?
    ) -> Self {
        CommonTokenFeeProvider(
            feeTokenItem: feeTokenItem,
            supportingOptions: supportingOptions,
            availableTokenBalanceProvider: availableTokenBalanceProvider,
            tokenFeeLoader: tokenFeeLoader,
            customFeeProvider: customFeeProvider,
        )
    }

    static func gasless(
        walletModel: any WalletModel,
        feeWalletModel: any WalletModel,
        supportingOptions: TokenFeeProviderSupportingOptions,
    ) -> Self {
        let tokenFeeLoader = TokenFeeLoaderBuilder.makeGaslessTokenFeeLoader(
            walletModel: walletModel,
            feeWalletModel: feeWalletModel
        )

        return CommonTokenFeeProvider(
            // Important! The `feeTokenItem` is tokenItem, means USDT / USDC
            feeTokenItem: feeWalletModel.tokenItem,
            supportingOptions: supportingOptions,
            availableTokenBalanceProvider: feeWalletModel.availableBalanceProvider,
            tokenFeeLoader: tokenFeeLoader,
            // Gasless doesn't support custom fee
            customFeeProvider: .none
        )
    }
}
