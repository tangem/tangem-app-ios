//
//  YieldSupplyServiceFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BigInt

final class YieldSupplyServiceFactory {
    let wallet: Wallet
    let dataStorage: BlockchainDataStorage
    let isYieldModuleUpdateEnabled: Bool

    init(
        wallet: Wallet,
        dataStorage: BlockchainDataStorage,
        isYieldModuleUpdateEnabled: Bool
    ) {
        self.wallet = wallet
        self.dataStorage = dataStorage
        self.isYieldModuleUpdateEnabled = isYieldModuleUpdateEnabled
    }

    func makeProvider(networkService: EthereumNetworkService) -> YieldSupplyService? {
        let contractAddressFactory = YieldSupplyContractAddressFactory(
            blockchain: wallet.blockchain,
            isYieldModuleUpdateEnabled: isYieldModuleUpdateEnabled
        )

        guard contractAddressFactory.isSupported, wallet.blockchain.isEvm else { return nil }

        return EthereumYieldSupplyService(
            networkService: networkService,
            wallet: wallet,
            contractAddressFactory: contractAddressFactory,
            dataStorage: dataStorage
        )
    }
}
