//
//  DependenciesFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemExpress
import BlockchainSdk

class CommonExpressModulesFactory {
    @Injected(\.expressPendingTransactionsRepository)
    private var pendingTransactionRepository: ExpressPendingTransactionRepository

    @Injected(\.expressPairsRepository)
    private var expressPairsRepository: ExpressPairsRepository

    private let userWalletInfo: UserWalletInfo
    private let userTokensManager: UserTokensManager
    private let walletModelsManager: WalletModelsManager

    private let initialWalletModel: any WalletModel
    private let destinationWalletModel: (any WalletModel)?
    private let expressAPIProviderFactory = ExpressAPIProviderFactory()

    // MARK: - Internal

    private lazy var expressInteractor = makeExpressInteractor()
    private lazy var expressAPIProvider = makeExpressAPIProvider()
    private lazy var expressRepository = makeExpressRepository()

    init(inputModel: InputModel) {
        userWalletInfo = inputModel.userWalletInfo
        userTokensManager = inputModel.userTokensManager
        walletModelsManager = inputModel.walletModelsManager
        initialWalletModel = inputModel.initialWalletModel
        destinationWalletModel = inputModel.destinationWalletModel
    }
}

// MARK: - ExpressModulesFactory

extension CommonExpressModulesFactory: ExpressModulesFactory {
    func makeExpressViewModel(coordinator: ExpressRoutable) -> ExpressViewModel {
        let notificationManager = notificationManager
        let model = ExpressViewModel(
            initialWallet: initialWalletModel,
            userWalletInfo: userWalletInfo,
            feeFormatter: feeFormatter,
            balanceFormatter: balanceFormatter,
            expressProviderFormatter: expressProviderFormatter,
            notificationManager: notificationManager,
            expressRepository: expressRepository,
            interactor: expressInteractor,
            coordinator: coordinator
        )
        notificationManager.setupManager(with: model)
        return model
    }

    func makeExpressTokensListViewModel(
        swapDirection: ExpressTokensListViewModel.SwapDirection,
        coordinator: ExpressTokensListRoutable
    ) -> ExpressTokensListViewModel {
        ExpressTokensListViewModel(
            swapDirection: swapDirection,
            expressTokensListAdapter: expressTokensListAdapter,
            expressPairsRepository: expressPairsRepository,
            expressInteractor: expressInteractor,
            coordinator: coordinator,
            userWalletModelConfig: userWalletInfo.config
        )
    }

    func makeExpressFeeSelectorViewModel(coordinator: ExpressFeeSelectorRoutable) -> ExpressFeeSelectorViewModel {
        ExpressFeeSelectorViewModel(
            feeFormatter: feeFormatter,
            expressInteractor: expressInteractor,
            coordinator: coordinator
        )
    }

    func makeExpressApproveViewModel(
        providerName: String,
        selectedPolicy: BSDKApprovePolicy,
        coordinator: ExpressApproveRoutable
    ) -> ExpressApproveViewModel {
        let tokenItem = expressInteractor.getSender().tokenItem

        return ExpressApproveViewModel(
            settings: .init(
                subtitle: Localization.givePermissionSwapSubtitle(providerName, tokenItem.currencySymbol),
                feeFooterText: Localization.swapGivePermissionFeeFooter,
                tokenItem: tokenItem,
                feeTokenItem: expressInteractor.getSender().feeTokenItem,
                selectedPolicy: selectedPolicy
            ),
            feeFormatter: feeFormatter,
            approveViewModelInput: expressInteractor,
            coordinator: coordinator
        )
    }

    func makeExpressProvidersSelectorViewModel(
        coordinator: ExpressProvidersSelectorRoutable
    ) -> ExpressProvidersSelectorViewModel {
        ExpressProvidersSelectorViewModel(
            priceChangeFormatter: priceChangeFormatter,
            expressProviderFormatter: expressProviderFormatter,
            expressRepository: expressRepository,
            expressInteractor: expressInteractor,
            coordinator: coordinator
        )
    }

    func makeExpressSuccessSentViewModel(data: SentExpressTransactionData, coordinator: ExpressSuccessSentRoutable) -> ExpressSuccessSentViewModel {
        ExpressSuccessSentViewModel(
            data: data,
            initialWallet: initialWalletModel,
            balanceConverter: balanceConverter,
            balanceFormatter: balanceFormatter,
            providerFormatter: providerFormatter,
            feeFormatter: feeFormatter,
            coordinator: coordinator
        )
    }

    func makePendingExpressTransactionsManager() -> any PendingExpressTransactionsManager {
        let tokenFinder = CommonTokenFinder(supportedBlockchains: userWalletInfo.config.supportedBlockchains)

        let expressRefundedTokenHandler = CommonExpressRefundedTokenHandler(
            userTokensManager: userTokensManager,
            tokenFinder: tokenFinder
        )

        let expressAPIProvider = makeExpressAPIProvider()

        let pendingExpressTransactionsManager = CommonPendingExpressTransactionsManager(
            userWalletId: userWalletInfo.id.stringValue,
            walletModel: initialWalletModel,
            expressAPIProvider: expressAPIProvider,
            expressRefundedTokenHandler: expressRefundedTokenHandler
        )

        let pendingOnrampTransactionsManager = CommonPendingOnrampTransactionsManager(
            userWalletId: userWalletInfo.id.stringValue,
            walletModel: initialWalletModel,
            expressAPIProvider: expressAPIProvider
        )

        return CompoundPendingTransactionsManager(
            first: pendingExpressTransactionsManager,
            second: pendingOnrampTransactionsManager
        )
    }
}

// MARK: Dependencies

private extension CommonExpressModulesFactory {
    var feeFormatter: FeeFormatter {
        CommonFeeFormatter(
            balanceFormatter: balanceFormatter,
            balanceConverter: balanceConverter
        )
    }

    var expressProviderFormatter: ExpressProviderFormatter {
        ExpressProviderFormatter(balanceFormatter: balanceFormatter)
    }

    var notificationManager: NotificationManager {
        ExpressNotificationManager(
            userWalletId: userWalletInfo.id,
            expressInteractor: expressInteractor
        )
    }

    var priceChangeFormatter: PriceChangeFormatter { .init() }
    var balanceConverter: BalanceConverter { .init() }
    var balanceFormatter: BalanceFormatter { .init() }
    var providerFormatter: ExpressProviderFormatter { .init(balanceFormatter: balanceFormatter) }

    /// Be careful to use tokenItem in CommonExpressAnalyticsLogger
    /// Becase there will be inly initial tokenItem without updating
    var analyticsLogger: ExpressAnalyticsLogger { CommonExpressAnalyticsLogger(tokenItem: initialWalletModel.tokenItem) }

    var expressTokensListAdapter: ExpressTokensListAdapter {
        CommonExpressTokensListAdapter(
            userTokensManager: userTokensManager,
            walletModelsManager: walletModelsManager
        )
    }

    var expressDestinationService: ExpressDestinationService {
        CommonExpressDestinationService(
            walletModelsManager: walletModelsManager
        )
    }

    // MARK: - Methods

    func makeExpressRepository() -> ExpressRepository {
        CommonExpressRepository(expressAPIProvider: expressAPIProvider)
    }

    func makeExpressAPIProvider() -> ExpressAPIProvider {
        expressAPIProviderFactory.makeExpressAPIProvider(
            userWalletId: userWalletInfo.id,
            refcode: userWalletInfo.refcode
        )
    }

    func makeExpressInteractor() -> ExpressInteractor {
        let transactionValidator = CommonExpressProviderTransactionValidator(
            tokenItem: initialWalletModel.tokenItem,
            hardwareLimitationsUtil: HardwareLimitationsUtil(config: userWalletInfo.config)
        )

        let expressManager = TangemExpressFactory().makeExpressManager(
            expressAPIProvider: expressAPIProvider,
            expressRepository: expressRepository,
            analyticsLogger: analyticsLogger,
            supportedProviderTypes: .swap,
            operationType: .swap,
            transactionValidator: transactionValidator
        )

        let interactor = ExpressInteractor(
            userWalletInfo: userWalletInfo,
            initialWallet: initialWalletModel.asExpressInteractorWallet,
            destinationWallet: destinationWalletModel.map { .success($0.asExpressInteractorWallet) } ?? .loading,
            expressManager: expressManager,
            expressPairsRepository: expressPairsRepository,
            expressPendingTransactionRepository: pendingTransactionRepository,
            expressDestinationService: expressDestinationService,
            expressAnalyticsLogger: analyticsLogger,
            expressAPIProvider: expressAPIProvider,
        )

        return interactor
    }
}

extension CommonExpressModulesFactory {
    struct InputModel {
        let userWalletInfo: UserWalletInfo
        let userTokensManager: UserTokensManager
        let walletModelsManager: WalletModelsManager
        let initialWalletModel: any WalletModel
        let destinationWalletModel: (any WalletModel)?

        init(
            userWalletInfo: UserWalletInfo,
            userTokensManager: UserTokensManager,
            walletModelsManager: WalletModelsManager,
            initialWalletModel: any WalletModel,
            destinationWalletModel: (any WalletModel)?
        ) {
            self.userWalletInfo = userWalletInfo
            self.userTokensManager = userTokensManager
            self.walletModelsManager = walletModelsManager
            self.initialWalletModel = initialWalletModel
            self.destinationWalletModel = destinationWalletModel
        }
    }
}
