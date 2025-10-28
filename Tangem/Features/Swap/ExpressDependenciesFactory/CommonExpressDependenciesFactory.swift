//
//  CommonExpressDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemFoundation

class CommonExpressDependenciesFactory: ExpressDependenciesFactory {
    @Injected(\.onrampRepository) private var _onrampRepository: OnrampRepository
    @Injected(\.expressPairsRepository) private var expressPairsRepository: any ExpressPairsRepository

    private let input: Input
    private let initialWallet: any ExpressInteractorSourceWallet
    private let destinationWallet: ExpressInteractor.Destination?
    private let supportedProviderTypes: [ExpressProviderType]
    private let operationType: ExpressOperationType

    private let expressAPIProviderFactory = ExpressAPIProviderFactory()
    @Injected(\.expressPendingTransactionsRepository)
    private var pendingTransactionRepository: ExpressPendingTransactionRepository

    private(set) lazy var expressInteractor = makeExpressInteractor()
    private(set) lazy var expressAPIProvider = makeExpressAPIProvider()
    private(set) lazy var expressRepository = makeExpressRepository()
    private(set) lazy var onrampRepository = makeOnrampRepository()

    init(
        input: Input,
        initialWallet: any ExpressInteractorSourceWallet,
        destinationWallet: ExpressInteractor.Destination?,
        supportedProviderTypes: [ExpressProviderType],
        operationType: ExpressOperationType
    ) {
        self.input = input
        self.initialWallet = initialWallet
        self.destinationWallet = destinationWallet
        self.supportedProviderTypes = supportedProviderTypes
        self.operationType = operationType
    }
}

// MARK: - Private

private extension CommonExpressDependenciesFactory {
    func makeExpressInteractor() -> ExpressInteractor {
        let transactionValidator = CommonExpressProviderTransactionValidator(
            tokenItem: initialWallet.tokenItem,
            hardwareLimitationsUtil: HardwareLimitationsUtil(config: input.userWalletInfo.config)
        )

        let expressManager = TangemExpressFactory().makeExpressManager(
            expressAPIProvider: expressAPIProvider,
            expressRepository: expressRepository,
            analyticsLogger: analyticsLogger,
            supportedProviderTypes: supportedProviderTypes,
            operationType: operationType,
            transactionValidator: transactionValidator
        )

        let interactor = ExpressInteractor(
            userWalletInfo: input.userWalletInfo,
            initialWallet: initialWallet,
            destinationWallet: destinationWallet,
            expressManager: expressManager,
            expressPairsRepository: expressPairsRepository,
            expressPendingTransactionRepository: pendingTransactionRepository,
            expressDestinationService: CommonExpressDestinationService(userWalletId: input.userWalletInfo.id),
            expressAnalyticsLogger: analyticsLogger,
            expressAPIProvider: expressAPIProvider
        )

        return interactor
    }

    func makeExpressRepository() -> ExpressRepository {
        CommonExpressRepository(expressAPIProvider: expressAPIProvider)
    }

    func makeExpressAPIProvider() -> ExpressAPIProvider {
        expressAPIProviderFactory.makeExpressAPIProvider(
            userWalletId: input.userWalletInfo.id,
            refcode: input.userWalletInfo.refcode
        )
    }

    func makeOnrampRepository() -> OnrampRepository {
        // For UI tests, use UITestOnrampRepository with predefined values
        if AppEnvironment.current.isUITest {
            return UITestOnrampRepository()
        }

        return _onrampRepository
    }

    /// Be careful to use tokenItem in CommonExpressAnalyticsLogger
    /// Because there will be inly initial tokenItem without updating
    var analyticsLogger: ExpressAnalyticsLogger {
        CommonExpressAnalyticsLogger(tokenItem: initialWallet.tokenItem)
    }
}

extension CommonExpressDependenciesFactory {
    struct Input {
        let userWalletInfo: UserWalletInfo
        let walletModelsManager: WalletModelsManager

        init(
            userWalletInfo: UserWalletInfo,
            walletModelsManager: any WalletModelsManager
        ) {
            self.userWalletInfo = userWalletInfo
            self.walletModelsManager = walletModelsManager
        }
    }
}
