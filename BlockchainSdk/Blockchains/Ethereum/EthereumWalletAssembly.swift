//
//  EthereumChildWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct EthereumWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let wallet = input.wallet
        let blockchain = wallet.blockchain

        guard let chainId = blockchain.chainId else {
            throw ETHError.chainIdNotFound
        }

        // If you get an `invalidSourceAddress` error thrown here for a newly added EVM blockchain, double-check
        // which address from `wallet.addresses` can be used as a source address for transactions.
        // Almost always, it is the `wallet.defaultAddress`.
        // If that is the case, add your blockchain to the `case` statement with `xdc`, `decimal`, and other cases.
        switch (wallet.addresses.count, blockchain) {
        case (_, .xdc),
             (_, .decimal):
            break
        default:
            if wallet.addresses.count > 1 {
                throw ETHError.invalidSourceAddress
            }
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
            decimals: blockchain.decimalCount,
            providers: providers,
            abiEncoder: WalletCoreABIEncoder(),
            blockchainName: input.wallet.blockchain.displayName
        )

        let addressConverter = EthereumAddressConverterFactory().makeConverter(for: blockchain)

        let pendingTransactionsManager = CommonEthereumPendingTransactionsManager(
            walletAddress: wallet.address,
            blockchain: wallet.blockchain,
            networkService: networkService,
            dataStorage: input.blockchainSdkDependencies.dataStorage,
            addressConverter: addressConverter
        )

        return EthereumWalletManager(
            wallet: wallet,
            addressConverter: addressConverter,
            txBuilder: txBuilder,
            networkService: networkService,
            yieldSupplyService: yieldSupplyServiceFactory.makeProvider(networkService: networkService),
            pendingTransactionsManager: pendingTransactionsManager,
            allowsFeeSelection: blockchain.allowsFeeSelection
        )
    }
}
