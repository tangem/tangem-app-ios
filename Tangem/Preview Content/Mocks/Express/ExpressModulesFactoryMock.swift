//
//  ExpressModulesFactoryMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemExpress
import BlockchainSdk

class ExpressModulesFactoryMock: ExpressModulesFactory {
    private let initialWalletModel: any WalletModel = CommonWalletModel.mockETH
    private let userWalletModel: UserWalletModel = UserWalletModelMock()
    private let expressAPIProviderFactory = ExpressAPIProviderFactory()

    private lazy var pendingTransactionRepository = ExpressPendingTransactionRepositoryMock()
    private lazy var expressInteractor = makeExpressInteractor()
    private lazy var expressAPIProvider = makeExpressAPIProvider()
    private lazy var expressRepository = makeExpressRepository()

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
        ExpressApproveViewModel(
            settings: .init(
                subtitle: Localization.givePermissionSwapSubtitle(providerName, "USDT"),
                feeFooterText: Localization.swapGivePermissionFeeFooter,
                tokenItem: .token(.tetherMock, .init(.ethereum(testnet: false), derivationPath: .none)),
                feeTokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: .none)),
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
        CompoundPendingTransactionsManager(
            first: CommonPendingExpressTransactionsManager(
                userWalletId: userWalletModel.userWalletId.stringValue,
                walletModel: initialWalletModel,
                expressAPIProvider: makeExpressAPIProvider(),
                expressRefundedTokenHandler: ExpressRefundedTokenHandlerMock()
            ),
            second: CommonPendingOnrampTransactionsManager(
                userWalletId: userWalletModel.userWalletId.stringValue,
                walletModel: initialWalletModel,
                expressAPIProvider: makeExpressAPIProvider()
            )
        )
    }
}

// MARK: Dependencies

private extension ExpressModulesFactoryMock {
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
    var signer: TangemSigner { TangemSigner(filter: .cardId(""), sdk: TangemSdkDefaultFactory().makeTangemSdk(), twinKey: nil) }
    var userTokensManager: UserTokensManager { userWalletModel.userTokensManager }

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

    func makeExpressAPIProvider() -> ExpressAPIProvider {
        expressAPIProviderFactory.makeExpressAPIProvider(
            userWalletModel: userWalletModel
        )
    }

    func makeExpressInteractor() -> ExpressInteractor {
        let analyticsLogger = ExpressAnalyticsLoggerMock()

        let expressManager = TangemExpressFactory().makeExpressManager(
            expressAPIProvider: expressAPIProvider,
            expressRepository: expressRepository,
            analyticsLogger: analyticsLogger
        )

        let interactor = ExpressInteractor(
            userWalletId: userWalletId,
            initialWallet: initialWalletModel.asExpressInteractorWallet,
            destinationWallet: .loading,
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

    func makeExpressRepository() -> ExpressRepository {
        CommonExpressRepository(
            walletModelsManager: walletModelsManager,
            expressAPIProvider: expressAPIProvider
        )
    }
}
