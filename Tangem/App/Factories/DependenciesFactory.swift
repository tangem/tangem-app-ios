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
        source: Currency,
        destination: Currency?
    ) -> ExchangeManager {
        let networkService = BlockchainNetworkService(
            walletModel: walletModel,
            currencyMapper: createCurrencyMapper()
        )

        return TangemExchangeFactory().createExchangeManager(
            blockchainInfoProvider: networkService,
            source: source,
            destination: destination
        )
    }

    func createSwappingDestinationService(walletModel: WalletModel) -> SwappingDestinationServing {
        SwappingDestinationService(walletModel: walletModel, mapper: createCurrencyMapper())
    }

    func createCurrencyMapper() -> CurrencyMapping {
        CurrencyMapper()
    }

    func createTokenIconURLBuilder() -> TokenIconURLBuilding {
        TokenIconURLBuilder(baseURL: CoinsResponse.baseURL)
    }

    func createUserWalletsListProvider(walletModel: WalletModel) -> UserCurrenciesProviding {
        UserWalletListProvider(walletModel: walletModel)
    }

    func createTransactionSender(walletModel: WalletModel, signer: TransactionSigner) -> TransactionSenderProtocol {
        TransactionSender(walletModel: walletModel,
                          signer: signer,
                          currencyMapper: createCurrencyMapper())
    }
}
