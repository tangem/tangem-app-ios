//
//  TokenFeeLoaderBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

enum TokenFeeLoaderBuilder {
    static func makeTokenFeeLoader(
        tokenItem: TokenItem,
        feeTokenItem: TokenItem,
        walletManager: any WalletManager,
        isDemo: Bool
    ) -> TokenFeeLoader {
        if isDemo {
            return DemoTokenFeeLoader(tokenItem: tokenItem)
        }

        let tokenFeeLoader = CommonTokenFeeLoader(
            tokenItem: tokenItem,
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
                feeBlockchain: feeTokenItem.blockchain,
                tokenFeeLoader: tokenFeeLoader,
                ethereumNetworkProvider: walletManager
            )
        default:
            return tokenFeeLoader
        }
    }

    static func makeGaslessTokenFeeLoader(walletModel: any WalletModel, feeWalletModel: any WalletModel) -> TokenFeeLoader {
        guard let gaslessTransactionFeeProvider = feeWalletModel.ethereumGaslessTransactionFeeProvider else {
            return walletModel.makeTokenFeeLoader()
        }

        return CommonGaslessTokenFeeLoader(
            tokenItem: walletModel.tokenItem,
            feeToken: feeWalletModel.tokenItem.token,
            gaslessTransactionFeeProvider: gaslessTransactionFeeProvider
        )
    }
}
