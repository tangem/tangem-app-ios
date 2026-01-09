//
//  TokenFeeLoaderBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct TokenFeeProviderBuilder {
    func makeTokenFeeProviders(walletModel: any WalletModel) -> [TokenFeeProvider] {
        var supportedFeeItems = [walletModel]

        return supportedFeeItems.map { walletModel in
            
        }
    }
}

struct TokenFeeLoaderBuilder {
    func makeTokenFeeLoader(walletModel: any WalletModel, walletManager: any WalletManager) -> TokenFeeLoader {
        if walletModel.isDemo {
            return DemoTokenFeeLoader(tokenItem: walletModel.tokenItem)
        }

        let tokenFeeLoader = CommonTokenFeeLoader(
            tokenItem: walletModel.tokenItem,
            transactionFeeProvider: walletManager
        )

        if let compiledTransactionFeeProvider = walletManager as? CompiledTransactionFeeProvider {
            return CommonSolanaTokenFeeLoader(
                tokenFeeLoader: tokenFeeLoader,
                compiledTransactionFeeProvider: compiledTransactionFeeProvider
            )
        }

        if let ethereumNetworkProvider = walletManager as? EthereumNetworkProvider,
           let gaslessTransactionFeeProvider = walletManager as? GaslessTransactionFeeProvider {
            return CommonEthereumTokenFeeLoader(
                tokenItem: walletModel.tokenItem,
                tokenFeeLoader: tokenFeeLoader,
                ethereumNetworkProvider: ethereumNetworkProvider,
                gaslessTransactionFeeProvider: gaslessTransactionFeeProvider
            )
        }

        return tokenFeeLoader
    }
}
