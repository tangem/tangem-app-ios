//
//  YieldSupplyServiceFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BigInt

final class YieldSupplyServiceFactory {
    let wallet: Wallet
    let dataStorage: BlockchainDataStorage

    init(wallet: Wallet, dataStorage: BlockchainDataStorage) {
        self.wallet = wallet
        self.dataStorage = dataStorage
    }

    func makeProvider(networkService: EthereumNetworkService) -> YieldSupplyService? {
        let contractAddressFactory = YieldSupplyContractAddressFactory(blockchain: wallet.blockchain)

        guard contractAddressFactory.isSupported, wallet.blockchain.isEvm else { return nil }

        return EthereumYieldSupplyService(
            networkService: networkService,
            wallet: wallet,
            contractAddressFactory: contractAddressFactory,
            dataStorage: dataStorage
        )
    }
}
