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

protocol SwappingDependenciesFactoring {
    // [REDACTED_TODO_COMMENT]
    func walletModel() -> WalletModel
    func userTokenListManager() -> UserTokenListManager
    func exchangeManager(source: Currency, destination: Currency?) -> ExchangeManager
    func swappingDestinationService() -> SwappingDestinationServicing
    func currencyMapper() -> CurrencyMapping
    func tokenIconURLBuilder() -> TokenIconURLBuilding
    func userCurrenciesProvider() -> UserCurrenciesProviding
    func transactionSender() -> TransactionSendable
}

struct SwappingDependenciesFactory {
    // Think about it. Maybe in future we will implement it from AppDependenciesFactory
    private let _userTokenListManager: UserTokenListManager
    private let _walletModel: WalletModel
    private let signer: TransactionSigner
    private let logger: ExchangeLogger

    private var walletManager: WalletManager { _walletModel.walletManager }

    init(
        userTokenListManager: UserTokenListManager,
        walletModel: WalletModel,
        signer: TransactionSigner,
        logger: ExchangeLogger
    ) {
        _userTokenListManager = userTokenListManager
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

    func userTokenListManager() -> UserTokenListManager {
        return _userTokenListManager
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
