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
    func createTokenIconURLBuilder() -> TokenIconURLBuilding {
        TokenIconURLBuilder(baseURL: CoinsResponse.baseURL)
    }

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
}
