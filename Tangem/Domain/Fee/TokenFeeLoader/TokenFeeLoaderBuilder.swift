//
//  TokenFeeLoaderBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

enum TokenFeeLoaderBuilder {
    static func makeTokenFeeLoader(walletModel: any WalletModel, walletManager: any WalletManager) -> TokenFeeLoader {
        if walletModel.isDemo {
            return DemoTokenFeeLoader(tokenItem: walletModel.tokenItem)
        }

        let tokenFeeLoader = CommonTokenFeeLoader(
            tokenItem: walletModel.tokenItem,
            transactionFeeProvider: walletManager
        )

        switch walletManager {
        case let walletManager as CompiledTransactionFeeProvider:
            return CommonSolanaTokenFeeLoader(
                tokenFeeLoader: tokenFeeLoader,
                compiledTransactionFeeProvider: walletManager
            )
        case let walletManager as EthereumNetworkProvider:
            return CommonEthereumTokenFeeLoader(
                feeBlockchain: walletModel.feeTokenItem.blockchain,
                tokenFeeLoader: tokenFeeLoader,
                ethereumNetworkProvider: walletManager
            )
        default:
            return tokenFeeLoader
        }
    }

    static func makeGaslessTokenFeeLoader(walletModel: any WalletModel, feeWalletModel: any WalletModel) -> TokenFeeLoader {
        guard let gaslessTransactionFeeProvider = feeWalletModel.ethereumGaslessTransactionFeeProvider else {
            return walletModel.tokenFeeLoader
        }

        return CommonGaslessTokenFeeLoader(
            tokenItem: walletModel.tokenItem,
            feeToken: feeWalletModel.tokenItem.token,
            gaslessTransactionFeeProvider: gaslessTransactionFeeProvider
        )
    }
}
