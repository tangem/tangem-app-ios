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
        guard let chainId = input.wallet.blockchain.chainId else {
            throw EthereumWalletAssemblyError.chainIdNotFound
        }

        let txBuilder = EthereumTransactionBuilder(chainId: chainId)
        let networkService = EthereumNetworkService(
            decimals: input.wallet.blockchain.decimalCount,
            providers: networkProviderAssembly.makeEthereumJsonRpcProviders(with: input.networkInput),
            abiEncoder: WalletCoreABIEncoder()
        )

        let addressConverter = EthereumAddressConverterFactory().makeConverter(for: input.wallet.blockchain)

        return EthereumWalletManager(
            wallet: input.wallet,
            addressConverter: addressConverter,
            txBuilder: txBuilder,
            networkService: networkService,
            allowsFeeSelection: input.wallet.blockchain.allowsFeeSelection
        )
    }
}

enum EthereumWalletAssemblyError: Error {
    case chainIdNotFound
}
