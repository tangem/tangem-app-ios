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

class CommonSwappingModulesFactory {
    @Injected(\.keysManager) private var keysManager: KeysManager

    private let userTokensManager: UserTokensManager
    private let walletModel: WalletModel
    private let signer: TransactionSigner
    private let ethereumNetworkProvider: EthereumNetworkProvider
    private let ethereumTransactionProcessor: EthereumTransactionProcessor
    private let logger: SwappingLogger
    private let referrer: SwappingReferrerAccount?
    private let source: Currency
    private let walletModelTokens: [Token]
    private let walletModelsManager: WalletModelsManager
    private let userWalletId: String

    // MARK: - Internal

    private var _swappingInteractor: SwappingInteractor?

    private lazy var expressInteractor = makeExpressInteractor()
    private lazy var expressAPICredential = makeExpressAPICredential()
    private lazy var expressAPIProvider = makeExpressAPIProvider()
    private lazy var swappingFactory = TangemSwappingFactory()

    init(inputModel: InputModel) {
        userTokensManager = inputModel.userTokensManager
        walletModel = inputModel.walletModel
        signer = inputModel.signer
        ethereumNetworkProvider = inputModel.ethereumNetworkProvider
        ethereumTransactionProcessor = inputModel.ethereumTransactionProcessor
        logger = inputModel.logger
        referrer = inputModel.referrer
        source = inputModel.source
        walletModelTokens = inputModel.walletModelTokens
        walletModelsManager = inputModel.walletModelsManager
        userWalletId = inputModel.userWalletId
    }
}

// MARK: - SwappingModulesFactory

extension CommonSwappingModulesFactory: SwappingModulesFactory {
    func makeExpressViewModel(coordinator: ExpressRoutable) -> ExpressViewModel {
        ExpressViewModel(
            initialWallet: walletModel,
            swappingFeeFormatter: swappingFeeFormatter,
            balanceConverter: .init(),
            balanceFormatter: .init(),
            expressProviderFormatter: expressProviderFormatter,
            swappingInteractor: expressInteractor,
            coordinator: coordinator
        )
    }

    func makeSwappingViewModel(coordinator: SwappingRoutable) -> SwappingViewModel {
        SwappingViewModel(
            initialSourceCurrency: source,
            swappingInteractor: swappingInteractor,
            swappingDestinationService: swappingDestinationService,
            tokenIconURLBuilder: tokenIconURLBuilder,
            transactionSender: transactionSender,
            fiatRatesProvider: fiatRatesProvider,
            swappingFeeFormatter: swappingFeeFormatter,
            coordinator: coordinator
        )
    }

    func makeSwappingTokenListViewModel(coordinator: SwappingTokenListRoutable) -> SwappingTokenListViewModel {
        SwappingTokenListViewModel(
            blockchain: walletModel.wallet.blockchain,
            sourceCurrency: source,
            userCurrenciesProvider: userCurrenciesProvider,
            tokenIconURLBuilder: tokenIconURLBuilder,
            currencyMapper: currencyMapper,
            walletDataProvider: walletDataProvider,
            fiatRatesProvider: fiatRatesProvider,
            coordinator: coordinator
        )
    }

    func makeExpressTokensListViewModel(
        swapDirection: ExpressTokensListViewModel.SwapDirection,
        coordinator: ExpressTokensListRoutable
    ) -> ExpressTokensListViewModel {
        ExpressTokensListViewModel(
            swapDirection: swapDirection,
            walletModels: walletModelsManager.walletModels,
            expressAPIProvider: expressAPIProvider,
            expressInteractor: expressInteractor,
            coordinator: coordinator
        )
    }

    func makeExpressFeeSelectorViewModel(coordinator: ExpressFeeBottomSheetRoutable) -> ExpressFeeBottomSheetViewModel {
        ExpressFeeBottomSheetViewModel(
            swappingFeeFormatter: swappingFeeFormatter,
            expressInteractor: expressInteractor,
            coordinator: coordinator
        )
    }

    func makeSwappingApproveViewModel(coordinator: SwappingApproveRoutable) -> SwappingApproveViewModel {
        SwappingApproveViewModel(
            transactionSender: transactionSender,
            swappingInteractor: swappingInteractor,
            fiatRatesProvider: fiatRatesProvider,
            coordinator: coordinator
        )
    }

    func makeExpressProvidersBottomSheetViewModel(
        input: ExpressProvidersBottomSheetViewModel.InputModel,
        coordinator: ExpressProvidersBottomSheetRoutable
    ) -> ExpressProvidersBottomSheetViewModel {
        ExpressProvidersBottomSheetViewModel(
            input: input,
            percentFormatter: .init(),
            expressProviderFormatter: expressProviderFormatter,
            expressInteractor: expressInteractor,
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
    var swappingDestinationService: SwappingDestinationServicing {
        SwappingDestinationService(
            blockchain: walletModel.blockchainNetwork.blockchain,
            mapper: currencyMapper,
            walletModelTokens: walletModelTokens
        )
    }

    var currencyMapper: CurrencyMapping { CurrencyMapper() }

    var tokenIconURLBuilder: TokenIconURLBuilding { TokenIconURLBuilder() }

    var userCurrenciesProvider: UserCurrenciesProviding {
        UserCurrenciesProvider(
            blockchain: walletModel.blockchainNetwork.blockchain,
            walletModelTokens: walletModelTokens,
            currencyMapper: currencyMapper
        )
    }

    var transactionSender: SwappingTransactionSender {
        CommonSwappingTransactionSender(
            walletModel: walletModel,
            transactionSigner: signer,
            ethereumNetworkProvider: ethereumNetworkProvider,
            currencyMapper: currencyMapper
        )
    }

    var fiatRatesProvider: FiatRatesProviding {
        SwappingRatesProvider()
    }

    var swappingFeeFormatter: SwappingFeeFormatter {
        CommonSwappingFeeFormatter(
            balanceFormatter: .init(),
            balanceConverter: .init(),
            fiatRatesProvider: fiatRatesProvider
        )
    }

    var expressProviderFormatter: ExpressProviderFormatter {
        ExpressProviderFormatter(balanceFormatter: .init())
    }

    var explorerURLService: ExplorerURLService {
        CommonExplorerURLService()
    }

    var walletDataProvider: SwappingWalletDataProvider {
        CommonSwappingWalletDataProvider(
            wallet: walletModel.wallet,
            ethereumNetworkProvider: ethereumNetworkProvider,
            ethereumTransactionProcessor: ethereumTransactionProcessor,
            currencyMapper: currencyMapper
        )
    }

    var allowanceProvider: CommonAllowanceProvider {
        CommonAllowanceProvider(
            ethereumNetworkProvider: ethereumNetworkProvider,
            ethereumTransactionProcessor: ethereumTransactionProcessor
        )
    }

    var pendingTransactionRepository: ExpressPendingTransactionRepository {
        CommonExpressPendingTransactionRepository()
    }

    var expressDestinationService: ExpressDestinationService {
        CommonExpressDestinationService(walletModelsManager: walletModelsManager)
    }

    var swappingInteractor: SwappingInteractor {
        if let interactor = _swappingInteractor {
            return interactor
        }

        let swappingManager = TangemSwappingFactory().makeSwappingManager(
            walletDataProvider: walletDataProvider,
            referrer: referrer,
            source: source,
            destination: nil,
            logger: logger
        )

        let interactor = SwappingInteractor(
            swappingManager: swappingManager,
            userTokensManager: userTokensManager,
            currencyMapper: currencyMapper,
            blockchainNetwork: walletModel.blockchainNetwork
        )

        _swappingInteractor = interactor
        return interactor
    }

    // MARK: - Methods

    func makeExpressInteractor() -> ExpressInteractor {
        let expressManager = swappingFactory.makeExpressManager(
            expressAPIProvider: expressAPIProvider,
            allowanceProvider: allowanceProvider,
            logger: logger
        )

        let interactor = ExpressInteractor(
            sender: walletModel,
            expressManager: expressManager,
            allowanceProvider: allowanceProvider,
            expressPendingTransactionRepository: pendingTransactionRepository,
            expressDestinationService: expressDestinationService,
            signer: signer,
            logger: logger
        )

        return interactor
    }

    func makeExpressAPIProvider() -> ExpressAPIProvider {
        swappingFactory.makeExpressAPIProvider(
            credential: expressAPICredential,
            configuration: .defaultConfiguration,
            logger: logger
        )
    }

    func makeExpressAPICredential() -> ExpressAPICredential {
        ExpressAPICredential(
            apiKey: keysManager.tangemExpressApiKey,
            userId: userWalletId,
            sessionId: UUID().uuidString
        )
    }
}

extension CommonSwappingModulesFactory {
    struct InputModel {
        let userTokensManager: UserTokensManager
        let walletModel: WalletModel
        let signer: TransactionSigner
        let ethereumNetworkProvider: EthereumNetworkProvider
        let ethereumTransactionProcessor: EthereumTransactionProcessor
        let logger: SwappingLogger
        let referrer: SwappingReferrerAccount?
        let source: Currency
        let walletModelTokens: [Token]
        let walletModelsManager: WalletModelsManager
        let userWalletId: String
    }
}
