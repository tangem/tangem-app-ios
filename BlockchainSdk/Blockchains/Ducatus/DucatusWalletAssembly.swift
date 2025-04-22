//
//  DucatusWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct DucatusWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let unspentOutputManager: UnspentOutputManager = .ducatus(address: input.wallet.defaultAddress)
        let txBuilder = BitcoinTransactionBuilder(
            network: DucatusNetworkParams(),
            unspentOutputManager: unspentOutputManager
        )
        let networkService = BitcoreNetworkProvider(configuration: input.networkInput.tangemProviderConfig)
        return DucatusWalletManager(wallet: input.wallet, txBuilder: txBuilder, unspentOutputManager: unspentOutputManager, networkService: networkService)
    }
}
