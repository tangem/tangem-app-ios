//
//  QuaiWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct QuaiWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let wallet = input.wallet

        guard let chainId = wallet.blockchain.chainId else {
            throw ETHError.chainIdNotFound
        }

        let providers = networkProviderAssembly.makeEthereumJsonRpcProviders(with: input.networkInput)
        let txBuilder = QuaiTransactionBuilder(
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

        return EthereumWalletManager(
            wallet: wallet,
            addressConverter: addressConverter,
            txBuilder: txBuilder,
            networkService: networkService,
            allowsFeeSelection: wallet.blockchain.allowsFeeSelection
        )
    }
}
