//
//  DependenciesFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping
import BlockchainSdk

struct CommonSwappingModulesFactory {
    private let userWalletModel: UserWalletModel
    private let walletModel: WalletModel
    private let sender: TransactionSender
    private let signer: TransactionSigner
    private let logger: SwappingLogger
    private let referrer: SwappingReferrerAccount?
    private let source: Currency
    private let destination: Currency?

    init(inputModel: InputModel) {
        userWalletModel = inputModel.userWalletModel
        walletModel = inputModel.walletModel
        sender = inputModel.sender
        signer = inputModel.signer
        logger = inputModel.logger
        referrer = inputModel.referrer
        source = inputModel.source
        destination = inputModel.destination
    }
}

// MARK: - SwappingModulesFactory

extension CommonSwappingModulesFactory: SwappingModulesFactory {
    func makeSwappingViewModel(coordinator: SwappingRoutable) -> SwappingViewModel {
        SwappingViewModel(
            initialSourceCurrency: source,
            swappingManager: makeSwappingManager(source: source, destination: destination),
            swappingDestinationService: swappingDestinationService,
            tokenIconURLBuilder: tokenIconURLBuilder,
            transactionSender: transactionSender,
            fiatRatesProvider: fiatRatesProvider,
            userWalletModel: userWalletModel,
            currencyMapper: currencyMapper,
            blockchainNetwork: walletModel.blockchainNetwork,
            coordinator: coordinator
        )
    }

    func makeSwappingTokenListViewModel(coordinator: SwappingTokenListRoutable) -> SwappingTokenListViewModel {
        SwappingTokenListViewModel(
            sourceCurrency: source,
            userCurrenciesProvider: userCurrenciesProvider,
            tokenIconURLBuilder: tokenIconURLBuilder,
            currencyMapper: currencyMapper,
            walletDataProvider: walletDataProvider,
            fiatRatesProvider: fiatRatesProvider,
            coordinator: coordinator
        )
    }

    func makeSwappingPermissionViewModel(
        inputModel: SwappingPermissionInputModel,
        coordinator: SwappingPermissionRoutable
    ) -> SwappingPermissionViewModel {
        SwappingPermissionViewModel(
            inputModel: inputModel,
            transactionSender: transactionSender,
            coordinator: coordinator
        )
    }

    func makeSwappingSuccessViewModel(
        inputModel: SwappingSuccessInputModel,
        coordinator: SwappingSuccessRoutable
    ) -> SwappingSuccessViewModel {
        SwappingSuccessViewModel(
            inputModel: inputModel,
            explorerURLService: explorerURLService,
            coordinator: coordinator
        )
    }
}

// MARK: Dependencies

private extension CommonSwappingModulesFactory {
    var walletManager: WalletManager { walletModel.walletManager }

    var swappingDestinationService: SwappingDestinationServicing {
        SwappingDestinationService(walletModel: walletModel, mapper: currencyMapper)
    }

    var currencyMapper: CurrencyMapping { CurrencyMapper() }

    var tokenIconURLBuilder: TokenIconURLBuilding { TokenIconURLBuilder(baseURL: CoinsResponse.baseURL) }

    var userCurrenciesProvider: UserCurrenciesProviding {
        UserCurrenciesProvider(
            walletModel: walletModel,
            currencyMapper: currencyMapper
        )
    }

    var transactionSender: SwappingTransactionSender {
        CommonSwappingTransactionSender(
            transactionCreator: walletManager,
            transactionSender: walletManager,
            transactionSigner: signer,
            ethereumNetworkProvider: walletManager as! EthereumNetworkProvider,
            currencyMapper: currencyMapper
        )
    }

    var fiatRatesProvider: FiatRatesProviding {
        FiatRatesProvider(rates: walletModel.rates)
    }

    var explorerURLService: ExplorerURLService {
        CommonExplorerURLService()
    }

    var walletDataProvider: SwappingWalletDataProvider {
        CommonSwappingWalletDataProvider(
            wallet: walletModel.wallet,
            ethereumNetworkProvider: walletManager as! EthereumNetworkProvider,
            ethereumTransactionProcessor: walletManager as! EthereumTransactionProcessor,
            currencyMapper: currencyMapper
        )
    }

    func makeSwappingManager(source: Currency, destination: Currency?) -> SwappingManager {
        TangemSwappingFactory().makeSwappingManager(
            walletDataProvider: walletDataProvider,
            referrer: referrer,
            source: source,
            destination: destination,
            logger: logger
        )
    }
}

extension CommonSwappingModulesFactory {
    struct InputModel {
        let userWalletModel: UserWalletModel
        let walletModel: WalletModel
        let sender: TransactionSender
        let signer: TransactionSigner
        let logger: SwappingLogger
        let referrer: SwappingReferrerAccount?
        let source: Currency
        let destination: Currency?

        init(
            userWalletModel: UserWalletModel,
            walletModel: WalletModel,
            sender: TransactionSender,
            signer: TransactionSigner,
            logger: SwappingLogger,
            referrer: SwappingReferrerAccount?,
            source: Currency,
            destination: Currency? = nil
        ) {
            self.userWalletModel = userWalletModel
            self.walletModel = walletModel
            self.sender = sender
            self.signer = signer
            self.logger = logger
            self.referrer = referrer
            self.source = source
            self.destination = destination
        }
    }
}
