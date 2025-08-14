//
//  CommonExpressDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

class CommonExpressDependenciesFactory: ExpressDependenciesFactory {
    private let userWalletModel: UserWalletModel
    private let initialWallet: any ExpressInteractorSourceWallet
    private let destinationWallet: ExpressInteractor.Destination?
    private let supportedProviderTypes: [ExpressProviderType]

    private let expressAPIProviderFactory = ExpressAPIProviderFactory()
    @Injected(\.expressPendingTransactionsRepository)
    private var pendingTransactionRepository: ExpressPendingTransactionRepository

    private(set) lazy var expressInteractor = makeExpressInteractor()
    private(set) lazy var expressAPIProvider = makeExpressAPIProvider()
    private(set) lazy var expressRepository = makeExpressRepository()

    init(
        userWalletModel: UserWalletModel,
        initialWallet: any ExpressInteractorSourceWallet,
        destinationWallet: ExpressInteractor.Destination?,
        supportedProviderTypes: [ExpressProviderType]
    ) {
        self.userWalletModel = userWalletModel
        self.initialWallet = initialWallet
        self.destinationWallet = destinationWallet
        self.supportedProviderTypes = supportedProviderTypes
    }
}

// MARK: - Private

private extension CommonExpressDependenciesFactory {
    func makeExpressInteractor() -> ExpressInteractor {
        let expressManager = TangemExpressFactory().makeExpressManager(
            expressAPIProvider: expressAPIProvider,
            expressRepository: expressRepository,
            analyticsLogger: analyticsLogger,
            supportedProviderTypes: supportedProviderTypes
        )

        let interactor = ExpressInteractor(
            userWalletId: userWalletModel.userWalletId.stringValue,
            initialWallet: initialWallet,
            destinationWallet: destinationWallet,
            expressManager: expressManager,
            expressRepository: expressRepository,
            expressPendingTransactionRepository: pendingTransactionRepository,
            expressDestinationService: expressDestinationService,
            expressAnalyticsLogger: analyticsLogger,
            expressAPIProvider: expressAPIProvider,
            signer: userWalletModel.signer
        )

        return interactor
    }

    func makeExpressRepository() -> ExpressRepository {
        CommonExpressRepository(
            walletModelsManager: userWalletModel.walletModelsManager,
            expressAPIProvider: expressAPIProvider
        )
    }

    func makeExpressAPIProvider() -> ExpressAPIProvider {
        expressAPIProviderFactory.makeExpressAPIProvider(userWalletModel: userWalletModel)
    }

    /// Be careful to use tokenItem in CommonExpressAnalyticsLogger
    /// Because there will be inly initial tokenItem without updating
    var analyticsLogger: ExpressAnalyticsLogger {
        CommonExpressAnalyticsLogger(tokenItem: initialWallet.tokenItem)
    }

    var expressDestinationService: ExpressDestinationService {
        CommonExpressDestinationService(
            walletModelsManager: userWalletModel.walletModelsManager,
            expressRepository: expressRepository
        )
    }
}
