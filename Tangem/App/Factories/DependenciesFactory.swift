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
        signer: TangemSigner,
        source: Currency,
        destination: Currency?
    ) -> ExchangeManager {
        let networkService = BlockchainNetworkService(
            walletModel: walletModel,
            currencyMapper: createCurrencyMapper()
        )

        let signTypedDataProvider = createSignTypedDataProvider(
            walletManager: walletModel.walletManager,
            signer: signer
        )

        return TangemExchangeFactory().createExchangeManager(
            blockchainInfoProvider: networkService,
            signTypedDataProvider: signTypedDataProvider,
            source: source,
            destination: destination
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

    func createSignTypedDataProvider(walletManager: WalletManager, signer: TangemSigner) -> SignTypedDataProviding {
        SignTypedDataProvider(walletManager: walletManager,
                              tangemSigner: signer,
                              decimalNumberConverter: createDecimalNumberConverter())
    }

    func createDecimalNumberConverter() -> DecimalNumberConverting {
        DecimalNumberConverter()
    }
}
