//
//  TokenFeeProviderBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum TokenFeeProviderBuilder {
    static func makeTokenFeeProvider(walletModel: any WalletModel) -> any TokenFeeProvider {
        CommonTokenFeeProvider(
            feeTokenItem: walletModel.feeTokenItem,
            tokenFeeLoader: walletModel.tokenFeeLoader,
            customFeeProvider: walletModel.customFeeProvider
        )
    }

    static func makeGaslessTokenFeeProvider(walletModel: any WalletModel, feeWalletModel: any WalletModel) -> any TokenFeeProvider {
        let tokenFeeLoader = TokenFeeLoaderBuilder.makeGaslessTokenFeeLoader(walletModel: walletModel, feeWalletModel: feeWalletModel)
        return CommonTokenFeeProvider(
            // Important! The `feeTokenItem` is tokenItem, means USDT / USDC
            feeTokenItem: feeWalletModel.tokenItem,
            tokenFeeLoader: tokenFeeLoader,
            // Gasless doesn't support custom fee
            customFeeProvider: .none
        )
    }
}
