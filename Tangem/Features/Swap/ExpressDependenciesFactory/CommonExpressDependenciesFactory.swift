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
    private let initialSource: any ExpressInteractorSourceWallet
    private let initialDestination: ExpressInteractor.InitialDestinationType

    private let expressAPIProviderFactory = ExpressAPIProviderFactory()
    @Injected(\.expressPendingTransactionsRepository)
    private var pendingTransactionRepository: ExpressPendingTransactionRepository

    private(set) lazy var expressInteractor = makeExpressInteractor()
    private(set) lazy var expressAPIProvider = makeExpressAPIProvider()
    private(set) lazy var expressRepository = makeExpressRepository()

    init(
        userWalletModel: UserWalletModel,
        initialSource: any ExpressInteractorSourceWallet,
        initialDestination: ExpressInteractor.InitialDestinationType
    ) {
        self.userWalletModel = userWalletModel
        self.initialSource = initialSource
        self.initialDestination = initialDestination
    }
}

// MARK: - Private

private extension CommonExpressDependenciesFactory {
    func makeExpressInteractor() -> ExpressInteractor {
        let expressManager = TangemExpressFactory().makeExpressManager(
            expressAPIProvider: expressAPIProvider,
            expressRepository: expressRepository,
            analyticsLogger: analyticsLogger
        )

        let interactor = ExpressInteractor(
            userWalletId: userWalletModel.userWalletId.stringValue,
            initialWallet: initialSource,
            destination: initialDestination,
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
    /// Becase there will be inly initial tokenItem without updating
    var analyticsLogger: ExpressAnalyticsLogger { CommonExpressAnalyticsLogger(tokenItem: initialSource.tokenItem) }

    var expressDestinationService: ExpressDestinationService {
        CommonExpressDestinationService(
            walletModelsManager: userWalletModel.walletModelsManager,
            expressRepository: expressRepository
        )
    }
}
