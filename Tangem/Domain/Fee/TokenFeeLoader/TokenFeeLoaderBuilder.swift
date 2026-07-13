//
//  TokenFeeLoaderBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct TokenFeeLoaderBuilder {
    /// `TokenItem` which is sending.
    let tokenItem: TokenItem
    /// Provides all necessary dependencies for creating fee loaders.
    let dependenciesProvider: WalletModelDependenciesProvider
    let isDemo: Bool

    func makeMainTokenFeeLoader() -> TokenFeeLoader {
        if isDemo {
            return DemoTokenFeeLoader(tokenItem: tokenItem)
        }

        let transactionFeeProvider = dependenciesProvider.transactionFeeProvider
        let tokenFeeLoader = CommonTokenFeeLoader(
            tokenItem: tokenItem,
            transactionFeeProvider: transactionFeeProvider
        )

        if let compiledTransactionFeeProvider = dependenciesProvider.compiledTransactionFeeProvider {
            return CommonSolanaTokenFeeLoader(
                tokenFeeLoader: tokenFeeLoader,
                compiledTransactionFeeProvider: compiledTransactionFeeProvider
            )
        }

        if let ethereumNetworkProvider = dependenciesProvider.ethereumNetworkProvider {
            return CommonEthereumTokenFeeLoader(
                feeBlockchain: tokenItem.blockchain,
                tokenFeeLoader: tokenFeeLoader,
                ethereumNetworkProvider: ethereumNetworkProvider
            )
        }

        if case .bitcoin = tokenItem.blockchain {
            return CommonBitcoinTokenFeeLoader(tokenItem: tokenItem, tokenFeeLoader: tokenFeeLoader)
        }

        if let tronDexTransactionFeeProvider = transactionFeeProvider as? TronDexTransactionFeeProvider {
            return CommonTronTokenFeeLoader(tokenFeeLoader: tokenFeeLoader, tronDexTransactionFeeProvider: tronDexTransactionFeeProvider)
        }

        return tokenFeeLoader
    }

    func makeGaslessTokenFeeLoader(feeToken: BSDKToken, yieldFeeContext: GaslessYieldFeeContext?) -> TokenFeeLoader? {
        guard let gaslessTransactionFeeProvider = dependenciesProvider.ethereumGaslessTransactionFeeProvider else {
            assertionFailure("WalletModelDependenciesProvider does not have ethereumGaslessTransactionFeeProvider")
            return nil
        }

        return CommonGaslessTokenFeeLoader(
            tokenItem: tokenItem,
            feeToken: feeToken,
            gaslessTransactionFeeProvider: gaslessTransactionFeeProvider,
            yieldFeeContext: yieldFeeContext
        )
    }
}
