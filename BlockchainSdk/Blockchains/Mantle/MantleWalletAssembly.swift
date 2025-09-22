//
//  MantleWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MantleWalletAssembly: WalletManagerAssembly {
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
        let txBuilder = EthereumTransactionBuilder(
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

        return MantleWalletManager(
            wallet: wallet,
            addressConverter: addressConverter,
            txBuilder: txBuilder,
            networkService: networkService,
            yieldSupplyService: yieldSupplyServiceFactory.makeProvider(networkService: networkService),
            allowsFeeSelection: wallet.blockchain.allowsFeeSelection
        )
    }
}
