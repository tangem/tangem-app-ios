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
    @Injected(\.expressPendingTransactionsRepository) private var pendingTransactionRepository: ExpressPendingTransactionRepository

    private let userWalletModel: UserWalletModel
    private let initialWalletModel: any WalletModel
    private let destinationWalletModel: (any WalletModel)?
    private let expressAPIProviderFactory = ExpressAPIProviderFactory()

    // MARK: - Internal

    private lazy var expressInteractor = makeExpressInteractor()
    private lazy var expressAPIProvider = makeExpressAPIProvider()
    private lazy var expressRepository = makeExpressRepository()

    init(inputModel: InputModel) {
        userWalletModel = inputModel.userWalletModel
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
            userWalletModel: userWalletModel,
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
            expressRepository: expressRepository,
            expressInteractor: expressInteractor,
            coordinator: coordinator
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
        let tokenFinder = CommonTokenFinder(supportedBlockchains: userWalletModel.config.supportedBlockchains)

        let expressRefundedTokenHandler = CommonExpressRefundedTokenHandler(
            userTokensManager: userWalletModel.userTokensManager,
            tokenFinder: tokenFinder
        )

        let expressAPIProvider = makeExpressAPIProvider()

        let pendingExpressTransactionsManager = CommonPendingExpressTransactionsManager(
            userWalletId: userWalletModel.userWalletId.stringValue,
            walletModel: initialWalletModel,
            expressAPIProvider: expressAPIProvider,
            expressRefundedTokenHandler: expressRefundedTokenHandler
        )

        let pendingOnrampTransactionsManager = CommonPendingOnrampTransactionsManager(
            userWalletId: userWalletModel.userWalletId.stringValue,
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
        ExpressNotificationManager(expressInteractor: expressInteractor)
    }

    var priceChangeFormatter: PriceChangeFormatter { .init() }
    var balanceConverter: BalanceConverter { .init() }
    var balanceFormatter: BalanceFormatter { .init() }
    var providerFormatter: ExpressProviderFormatter { .init(balanceFormatter: balanceFormatter) }
    var walletModelsManager: WalletModelsManager { userWalletModel.walletModelsManager }
    var userWalletId: String { userWalletModel.userWalletId.stringValue }
    var signer: TangemSigner { userWalletModel.signer }

    /// Be careful to use tokenItem in CommonExpressAnalyticsLogger
    /// Becase there will be inly initial tokenItem without updating
    var analyticsLogger: ExpressAnalyticsLogger { CommonExpressAnalyticsLogger(tokenItem: initialWalletModel.tokenItem) }

    var expressTokensListAdapter: ExpressTokensListAdapter {
        CommonExpressTokensListAdapter(userWalletModel: userWalletModel)
    }

    var expressDestinationService: ExpressDestinationService {
        CommonExpressDestinationService(
            walletModelsManager: walletModelsManager,
            expressRepository: expressRepository
        )
    }

    // MARK: - Methods

    func makeExpressRepository() -> ExpressRepository {
        CommonExpressRepository(
            walletModelsManager: walletModelsManager,
            expressAPIProvider: expressAPIProvider
        )
    }

    func makeExpressAPIProvider() -> ExpressAPIProvider {
        expressAPIProviderFactory.makeExpressAPIProvider(userWalletModel: userWalletModel)
    }

    func makeExpressInteractor() -> ExpressInteractor {
        let expressManager = TangemExpressFactory().makeExpressManager(
            expressAPIProvider: expressAPIProvider,
            expressRepository: expressRepository,
            analyticsLogger: analyticsLogger
        )

        let interactor = ExpressInteractor(
            userWalletId: userWalletId,
            initialWallet: initialWalletModel.asExpressInteractorWallet,
            destinationWallet: destinationWalletModel.map { .success($0.asExpressInteractorWallet) } ?? .loading,
            expressManager: expressManager,
            expressRepository: expressRepository,
            expressPendingTransactionRepository: pendingTransactionRepository,
            expressDestinationService: expressDestinationService,
            expressAnalyticsLogger: analyticsLogger,
            expressAPIProvider: expressAPIProvider,
            signer: signer
        )

        return interactor
    }
}

extension CommonExpressModulesFactory {
    struct InputModel {
        let userWalletModel: UserWalletModel
        let initialWalletModel: any WalletModel
        let destinationWalletModel: (any WalletModel)?

        init(
            userWalletModel: UserWalletModel,
            initialWalletModel: any WalletModel,
            destinationWalletModel: (any WalletModel)? = nil
        ) {
            self.userWalletModel = userWalletModel
            self.initialWalletModel = initialWalletModel
            self.destinationWalletModel = destinationWalletModel
        }
    }
}
