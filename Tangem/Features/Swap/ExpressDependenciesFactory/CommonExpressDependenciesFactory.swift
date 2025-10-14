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
            requiresTransactionSizeValidation: input.requiresTransactionSizeValidation
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
            userWalletId: input.userWalletId.stringValue,
            initialWallet: initialWallet,
            destinationWallet: destinationWallet,
            expressManager: expressManager,
            expressRepository: expressRepository,
            expressPendingTransactionRepository: pendingTransactionRepository,
            expressDestinationService: expressDestinationService,
            expressAnalyticsLogger: analyticsLogger,
            expressAPIProvider: expressAPIProvider,
            signer: input.signer
        )

        return interactor
    }

    func makeExpressRepository() -> ExpressRepository {
        CommonExpressRepository(
            walletModelsManager: input.walletModelsManager,
            expressAPIProvider: expressAPIProvider
        )
    }

    func makeExpressAPIProvider() -> ExpressAPIProvider {
        expressAPIProviderFactory.makeExpressAPIProvider(userWalletId: input.userWalletId, refcode: input.refcode)
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

    var expressDestinationService: ExpressDestinationService {
        CommonExpressDestinationService(
            walletModelsManager: input.walletModelsManager,
            expressRepository: expressRepository
        )
    }
}

extension CommonExpressDependenciesFactory {
    struct Input {
        let userWalletId: UserWalletId
        let refcode: Refcode?
        let signer: TangemSigner
        let walletModelsManager: WalletModelsManager
        let requiresTransactionSizeValidation: Bool

        init(userWalletModel: UserWalletModel) {
            userWalletId = userWalletModel.userWalletId
            refcode = userWalletModel.refcodeProvider?.getRefcode()
            signer = userWalletModel.signer
            walletModelsManager = userWalletModel.walletModelsManager
            requiresTransactionSizeValidation = userWalletModel.config.hasFeature(.isHardwareLimited)
        }

        init(
            userWalletInfo: UserWalletInfo,
            refcode: Refcode?,
            walletModelsManager: any WalletModelsManager
        ) {
            userWalletId = userWalletInfo.id
            signer = userWalletInfo.signer
            requiresTransactionSizeValidation = userWalletInfo.config.hasFeature(.isHardwareLimited)

            self.refcode = refcode
            self.walletModelsManager = walletModelsManager
        }
    }
}
