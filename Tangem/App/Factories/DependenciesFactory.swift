//
//  DependenciesFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemExchange
import BlockchainSdk

struct DependenciesFactory {
    func createExchangeManager(
        walletModel: WalletModel,
        signer: TransactionSigner,
        source: Currency,
        destination: Currency
    ) -> ExchangeManager {
        let networkService = BlockchainNetworkService(walletModel: walletModel, signer: signer)

        return TangemExchangeFactory().createExchangeManager(
            transactionBuilder: networkService,
            blockchainInfoProvider: networkService,
            source: source,
            destination: destination
        )
    }

    func createUserWalletsListProvider(walletModel: WalletModel) -> UserWalletsListProviding {
        UserWalletsListProvider(walletModel: walletModel)
    }
}
