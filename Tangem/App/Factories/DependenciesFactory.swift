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
            destination: destination,
            logger: AppLog.shared
        )
    }

    func createSwappingDestinationService(walletModel: WalletModel) -> SwappingDestinationServicing {
        SwappingDestinationService(walletModel: walletModel, mapper: createCurrencyMapper())
    }

    func createCurrencyMapper() -> CurrencyMapping {
        CurrencyMapper()
    }

    func createTokenIconURLBuilder() -> TokenIconURLBuilding {
        TokenIconURLBuilder(baseURL: CoinsResponse.baseURL)
    }

    func createUserCurrenciesProvider(walletModel: WalletModel) -> UserCurrenciesProviding {
        UserCurrenciesProvider(walletModel: walletModel)
    }

    func createTransactionSender(sender: TransactionSender, signer: TransactionSigner) -> TransactionSendable {
        ExchangeTransactionSender(sender: sender,
                                  signer: signer,
                                  currencyMapper: createCurrencyMapper())
    }
}
