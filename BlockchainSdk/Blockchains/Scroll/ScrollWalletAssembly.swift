//
//  ScrollWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct ScrollWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let wallet = input.wallet

        guard let chainId = wallet.blockchain.chainId else {
            throw ETHError.chainIdNotFound
        }

        let yieldSupplyServiceFactory = YieldSupplyServiceFactory(
            wallet: wallet,
            dataStorage: input.blockchainSdkDependencies.dataStorage
        )

        let providers = networkProviderAssembly.makeEthereumJsonRpcProviders(with: input.networkInput)
        let txBuilder = CommonEthereumTransactionBuilder(
            chainId: chainId,
            sourceAddress: wallet.defaultAddress
        )
        let networkService = EthereumNetworkService(
            decimals: wallet.blockchain.decimalCount,
            providers: providers,
            abiEncoder: WalletCoreABIEncoder(),
            blockchainName: wallet.blockchain.displayName
        )

        let addressConverter = EthereumAddressConverterFactory().makeConverter(for: wallet.blockchain)

        let pendingTransactionsManager = CommonEthereumPendingTransactionsManager(
            walletAddress: wallet.address,
            blockchain: wallet.blockchain,
            networkService: networkService,
            dataStorage: input.blockchainSdkDependencies.dataStorage,
            addressConverter: addressConverter
        )

        let l1SmartContractAddress = EthereumOptimisticRollupConstants.scrollL1GasPriceOracleSmartContractAddress
        let l1FeeMultiplier = EthereumOptimisticRollupConstants.scrollL1GasFeeMultiplier

        return EthereumOptimisticRollupWalletManager(
            wallet: wallet,
            addressConverter: addressConverter,
            txBuilder: txBuilder,
            networkService: networkService,
            yieldSupplyService: yieldSupplyServiceFactory.makeProvider(networkService: networkService),
            pendingTransactionsManager: pendingTransactionsManager,
            allowsFeeSelection: wallet.blockchain.allowsFeeSelection,
            l1SmartContractAddress: l1SmartContractAddress,
            l1FeeMultiplier: l1FeeMultiplier
        )
    }
}
