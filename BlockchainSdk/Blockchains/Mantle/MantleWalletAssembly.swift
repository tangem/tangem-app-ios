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

        let apiList = APIList(dictionaryLiteral: (wallet.blockchain.networkId, input.networkInput.apiInfo))

        let serviceFactory = WalletNetworkServiceFactory(
            blockchainSdkKeysConfig: input.networkInput.keysConfig,
            tangemProviderConfig: input.networkInput.tangemProviderConfig,
            apiList: apiList
        )

        let networkService: EthereumNetworkService = try serviceFactory.makeServiceWithType(for: wallet.blockchain)

        let txBuilder = CommonEthereumTransactionBuilder(
            chainId: chainId,
            sourceAddress: wallet.defaultAddress
        )

        let addressConverter = EthereumAddressConverterFactory().makeConverter(for: wallet.blockchain)

        let pendingTransactionsManager = CommonEthereumPendingTransactionsManager(
            walletAddress: wallet.address,
            blockchain: wallet.blockchain,
            networkService: networkService,
            networkServiceFactory: serviceFactory,
            dataStorage: input.blockchainSdkDependencies.dataStorage,
            addressConverter: addressConverter
        )

        return MantleWalletManager(
            wallet: wallet,
            addressConverter: addressConverter,
            txBuilder: txBuilder,
            networkService: networkService,
            pendingTransactionsManager: pendingTransactionsManager,
            allowsFeeSelection: wallet.blockchain.allowsFeeSelection
        )
    }
}
