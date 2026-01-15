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
    var balanceState: FormattedTokenBalanceType { get }

    var state: TokenFeeProviderState { get }
    var statePublisher: AnyPublisher<TokenFeeProviderState, Never> { get }

    var fees: [LoadableTokenFee] { get }
    var feesPublisher: AnyPublisher<[LoadableTokenFee], Never> { get }

    func setup(input: TokenFeeProviderInputData)
    func updateFees() async
}

extension TokenFeeProvider where Self == EmptyTokenFeeProvider {
    static func empty(feeTokenItem: TokenItem) -> Self {
        EmptyTokenFeeProvider(feeTokenItem: feeTokenItem)
    }
}

extension TokenFeeProvider where Self == CommonTokenFeeProvider {
    static func common(
        feeTokenItem: TokenItem,
        availableTokenBalanceProvider: TokenBalanceProvider,
        tokenFeeLoader: any TokenFeeLoader,
        customFeeProvider: (any CustomFeeProvider)?
    ) -> Self {
        CommonTokenFeeProvider(
            feeTokenItem: feeTokenItem,
            availableTokenBalanceProvider: availableTokenBalanceProvider,
            tokenFeeLoader: tokenFeeLoader,
            customFeeProvider: customFeeProvider,
        )
    }

    static func gasless(walletModel: any WalletModel, feeWalletModel: any WalletModel) -> Self {
        let tokenFeeLoader = TokenFeeLoaderBuilder.makeGaslessTokenFeeLoader(
            walletModel: walletModel,
            feeWalletModel: feeWalletModel
        )

        return CommonTokenFeeProvider(
            // Important! The `feeTokenItem` is tokenItem, means USDT / USDC
            feeTokenItem: feeWalletModel.tokenItem,
            availableTokenBalanceProvider: feeWalletModel.availableBalanceProvider,
            tokenFeeLoader: tokenFeeLoader,
            // Gasless doesn't support custom fee
            customFeeProvider: .none
        )
    }
}
