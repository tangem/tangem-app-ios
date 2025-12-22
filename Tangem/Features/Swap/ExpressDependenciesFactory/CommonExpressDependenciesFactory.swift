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
    @Injected(\.onrampRepository)
    private var _onrampRepository: OnrampRepository

    @Injected(\.expressPairsRepository)
    private var expressPairsRepository: any ExpressPairsRepository

    @Injected(\.expressPendingTransactionsRepository)
    private var pendingTransactionRepository: ExpressPendingTransactionRepository

    private let userWalletInfo: UserWalletInfo
    private let initialTokenItem: TokenItem
    private let swappingPair: ExpressInteractor.SwappingPair

    private let supportedProviderTypes: [ExpressProviderType]
    private let operationType: ExpressOperationType

    private let expressAPIProviderFactory = ExpressAPIProviderFactory()

    private(set) lazy var expressInteractor = makeExpressInteractor()
    private(set) lazy var expressAPIProvider = makeExpressAPIProvider()
    private(set) lazy var expressRepository = makeExpressRepository()
    private(set) lazy var onrampRepository = makeOnrampRepository()

    init(
        input: ExpressDependenciesInput,
        supportedProviderTypes: [ExpressProviderType],
        operationType: ExpressOperationType
    ) {
        userWalletInfo = input.userWalletInfo
        initialTokenItem = input.source.tokenItem

        swappingPair = .init(
            sender: .success(input.source),
            destination: input.destination.asExpressInteractorDestination
        )

        self.supportedProviderTypes = supportedProviderTypes
        self.operationType = operationType
    }

    init(
        input: ExpressDependenciesDestinationInput,
        supportedProviderTypes: [ExpressProviderType],
        operationType: ExpressOperationType
    ) {
        userWalletInfo = input.userWalletInfo
        initialTokenItem = input.destination.tokenItem

        swappingPair = .init(
            sender: .loading,
            destination: .success(input.destination)
        )

        self.supportedProviderTypes = supportedProviderTypes
        self.operationType = operationType
    }
}

// MARK: - Private

private extension CommonExpressDependenciesFactory {
    func makeExpressInteractor() -> ExpressInteractor {
        let transactionValidator = CommonExpressProviderTransactionValidator(
            tokenItem: initialTokenItem,
            hardwareLimitationsUtil: HardwareLimitationsUtil(config: userWalletInfo.config)
        )

        let expressManager = TangemExpressFactory().makeExpressManager(
            expressAPIProvider: expressAPIProvider,
            expressRepository: expressRepository,
            supportedProviderTypes: supportedProviderTypes,
            operationType: operationType,
            transactionValidator: transactionValidator
        )

        let shouldFilterForOneWallet = !FeatureProvider.isAvailable(.accounts)
        let interactor = ExpressInteractor(
            userWalletInfo: userWalletInfo,
            swappingPair: swappingPair,
            expressManager: expressManager,
            expressPairsRepository: expressPairsRepository,
            expressPendingTransactionRepository: pendingTransactionRepository,
            expressDestinationService: CommonExpressDestinationService(
                userWalletId: shouldFilterForOneWallet ? userWalletInfo.id : nil
            ),
            expressAPIProvider: expressAPIProvider
        )

        return interactor
    }

    func makeExpressRepository() -> ExpressRepository {
        CommonExpressRepository(expressAPIProvider: expressAPIProvider)
    }

    func makeExpressAPIProvider() -> ExpressAPIProvider {
        expressAPIProviderFactory.makeExpressAPIProvider(
            userWalletId: userWalletInfo.id,
            refcode: userWalletInfo.refcode
        )
    }

    func makeOnrampRepository() -> OnrampRepository {
        // For UI tests, use UITestOnrampRepository with predefined values
        if AppEnvironment.current.isUITest {
            return UITestOnrampRepository()
        }

        return _onrampRepository
    }
}

// MARK: - ExpressDependenciesInput.PredefinedDestination+

extension ExpressDependenciesInput.PredefinedDestination {
    var asExpressInteractorDestination: ExpressInteractor.Destination? {
        switch self {
        case .none: .none
        case .loadingAndSet: .loading
        case .chosen(let wallet): .success(wallet)
        }
    }
}
