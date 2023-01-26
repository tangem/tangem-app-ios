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

struct SwappingDependenciesFactory {
    private let _userWalletModel: UserWalletModel
    private let _walletModel: WalletModel
    private let signer: TransactionSigner
    private let logger: ExchangeLogger

    private var walletManager: WalletManager { _walletModel.walletManager }

    // Think about it. Maybe in future we will create this factory from AppDependenciesFactory
    init(
        userWalletModel: UserWalletModel,
        walletModel: WalletModel,
        signer: TransactionSigner,
        logger: ExchangeLogger
    ) {
        _userWalletModel = userWalletModel
        _walletModel = walletModel
        self.signer = signer
        self.logger = logger
    }
}

// MARK: - SwappingDependenciesFactoring

extension SwappingDependenciesFactory: SwappingDependenciesFactoring {
    func walletModel() -> WalletModel {
        return _walletModel
    }

    func userWalletModel() -> UserWalletModel {
        return _userWalletModel
    }

    func exchangeManager(source: Currency, destination: Currency?) -> ExchangeManager {
        let networkService = BlockchainNetworkService(
            walletModel: _walletModel,
            currencyMapper: currencyMapper()
        )

        return TangemExchangeFactory().createExchangeManager(
            blockchainInfoProvider: networkService,
            source: source,
            destination: destination,
            logger: logger
        )
    }

    func swappingDestinationService() -> SwappingDestinationServicing {
        SwappingDestinationService(walletModel: _walletModel, mapper: currencyMapper())
    }

    func currencyMapper() -> CurrencyMapping {
        CurrencyMapper()
    }

    func tokenIconURLBuilder() -> TokenIconURLBuilding {
        TokenIconURLBuilder(baseURL: CoinsResponse.baseURL)
    }

    func userCurrenciesProvider() -> UserCurrenciesProviding {
        UserCurrenciesProvider(walletModel: _walletModel)
    }

    func transactionSender() -> TransactionSendable {
        ExchangeTransactionSender(
            transactionCreator: walletManager,
            transactionSender: walletManager,
            transactionSigner: signer,
            currencyMapper: currencyMapper()
        )
    }
}
