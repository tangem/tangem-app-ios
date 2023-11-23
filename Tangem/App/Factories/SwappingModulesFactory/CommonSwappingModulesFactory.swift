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

    private let userWalletModel: UserWalletModel
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
        userWalletModel = inputModel.userWalletModel
        userTokensManager = userWalletModel.userTokensManager
        walletModel = inputModel.walletModel
        signer = inputModel.signer
        ethereumNetworkProvider = inputModel.ethereumNetworkProvider
        ethereumTransactionProcessor = inputModel.ethereumTransactionProcessor
        logger = inputModel.logger
        referrer = inputModel.referrer
        source = inputModel.source
        walletModelTokens = inputModel.walletModelTokens
        walletModelsManager = userWalletModel.walletModelsManager
        userWalletId = userWalletModel.userWalletId.stringValue
    }
}

// MARK: - SwappingModulesFactory

extension CommonSwappingModulesFactory: SwappingModulesFactory {
    func makeExpressViewModel(coordinator: ExpressRoutable) -> ExpressViewModel {
        let notificationManager = notificationManager
        let model = ExpressViewModel(
            initialWallet: walletModel,
            userWalletModel: userWalletModel,
            swappingFeeFormatter: swappingFeeFormatter,
            balanceConverter: balanceConverter,
            balanceFormatter: balanceFormatter,
            expressProviderFormatter: expressProviderFormatter,
            notificationManager: notificationManager,
            interactor: expressInteractor,
            coordinator: coordinator
        )
        notificationManager.setupManager(with: model)
        return model
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
            fiatRatesProvider: fiatRatesProvider,
            swappingInteractor: swappingInteractor,
            swappingFeeFormatter: swappingFeeFormatter,
            pendingTransactionRepository: pendingTransactionRepository,
            logger: logger,
            expressInteractor: expressInteractor,
            coordinator: coordinator
        )
    }

    func makeExpressProvidersBottomSheetViewModel(
        coordinator: ExpressProvidersBottomSheetRoutable
    ) -> ExpressProvidersBottomSheetViewModel {
        ExpressProvidersBottomSheetViewModel(
            percentFormatter: percentFormatter,
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

    func makeExpressSuccessSentViewModel(data: SentExpressTransactionData, coordinator: ExpressSuccessSentRoutable) -> ExpressSuccessSentViewModel {
        ExpressSuccessSentViewModel(
            data: data,
            balanceConverter: balanceConverter,
            balanceFormatter: balanceFormatter,
            providerFormatter: providerFormatter,
            feeFormatter: swappingFeeFormatter,
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
            balanceFormatter: balanceFormatter,
            balanceConverter: balanceConverter,
            fiatRatesProvider: fiatRatesProvider
        )
    }

    var expressProviderFormatter: ExpressProviderFormatter {
        ExpressProviderFormatter(balanceFormatter: balanceFormatter)
    }

    var notificationManager: ExpressNotificationManager {
        ExpressNotificationManager(expressInteractor: expressInteractor)
    }

    var explorerURLService: ExplorerURLService {
        CommonExplorerURLService()
    }

    var percentFormatter: PercentFormatter { .init() }
    var balanceConverter: BalanceConverter { .init() }
    var balanceFormatter: BalanceFormatter { .init() }
    var providerFormatter: ExpressProviderFormatter { .init(balanceFormatter: balanceFormatter) }

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
        CommonExpressDestinationService(
            pendingTransactionRepository: pendingTransactionRepository,
            walletModelsManager: walletModelsManager
        )
    }

    var expressTransactionBuilder: ExpressTransactionBuilder {
        CommonExpressTransactionBuilder()
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
            expressTransactionBuilder: expressTransactionBuilder,
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
        let userWalletModel: UserWalletModel
        let walletModel: WalletModel
        let signer: TransactionSigner
        let ethereumNetworkProvider: EthereumNetworkProvider
        let ethereumTransactionProcessor: EthereumTransactionProcessor
        let logger: SwappingLogger
        let referrer: SwappingReferrerAccount?
        let source: Currency
        let walletModelTokens: [Token]
    }
}
