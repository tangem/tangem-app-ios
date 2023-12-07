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

class CommonExpressModulesFactory {
    @Injected(\.keysManager) private var keysManager: KeysManager
    @Injected(\.expressPendingTransactionsRepository) private var pendingTransactionRepository: ExpressPendingTransactionRepository

    private let userWalletModel: UserWalletModel
    private let initialWalletModel: WalletModel
    private let expressAPIProviderFactory = ExpressAPIProviderFactory()

    // MARK: - Internal

    private lazy var expressInteractor = makeExpressInteractor()
    private lazy var swappingFactory = TangemSwappingFactory(oneInchApiKey: keysManager.oneInchApiKey)
    private lazy var allowanceProvider = makeAllowanceProvider()

    init(inputModel: InputModel) {
        userWalletModel = inputModel.userWalletModel
        initialWalletModel = inputModel.initialWalletModel
    }
}

// MARK: - ExpressModulesFactory

extension CommonExpressModulesFactory: ExpressModulesFactory {
    func makeExpressViewModel(coordinator: ExpressRoutable) -> ExpressViewModel {
        let notificationManager = notificationManager
        let model = ExpressViewModel(
            initialWallet: initialWalletModel,
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

    func makeExpressTokensListViewModel(
        swapDirection: ExpressTokensListViewModel.SwapDirection,
        coordinator: ExpressTokensListRoutable
    ) -> ExpressTokensListViewModel {
        ExpressTokensListViewModel(
            swapDirection: swapDirection,
            expressTokensListAdapter: expressTokensListAdapter,
            expressAPIProvider: expressAPIProviderFactory.makeExpressAPIProvider(userId: userWalletId, logger: logger),
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

    func makeExpressSuccessSentViewModel(data: SentExpressTransactionData, coordinator: ExpressSuccessSentRoutable) -> ExpressSuccessSentViewModel {
        ExpressSuccessSentViewModel(
            data: data,
            initialWallet: initialWalletModel,
            balanceConverter: balanceConverter,
            balanceFormatter: balanceFormatter,
            providerFormatter: providerFormatter,
            feeFormatter: swappingFeeFormatter,
            coordinator: coordinator
        )
    }
}

// MARK: Dependencies

private extension CommonExpressModulesFactory {
    var swappingFeeFormatter: SwappingFeeFormatter {
        CommonSwappingFeeFormatter(
            balanceFormatter: balanceFormatter,
            balanceConverter: balanceConverter,
            fiatRatesProvider: SwappingRatesProvider()
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
    var walletModelsManager: WalletModelsManager { userWalletModel.walletModelsManager }
    var userWalletId: String { userWalletModel.userWalletId.stringValue }
    var signer: TransactionSigner { userWalletModel.signer }
    var logger: SwappingLogger { AppLog.shared }
    var userTokensManager: UserTokensManager { userWalletModel.userTokensManager }

    var expressTokensListAdapter: ExpressTokensListAdapter {
        CommonExpressTokensListAdapter(userWalletModel: userWalletModel)
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

    // MARK: - Methods

    func makeExpressInteractor() -> ExpressInteractor {
        let expressManager = swappingFactory.makeExpressManager(
            expressAPIProvider: expressAPIProviderFactory.makeExpressAPIProvider(userId: userWalletId, logger: logger),
            allowanceProvider: allowanceProvider,
            logger: logger
        )

        let interactor = ExpressInteractor(
            userWalletId: userWalletId,
            initialWallet: initialWalletModel,
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

    func makeAllowanceProvider() -> ExpressAllowanceProvider {
        let provider = CommonExpressAllowanceProvider()
        provider.setup(wallet: initialWalletModel)
        return provider
    }
}

extension CommonExpressModulesFactory {
    struct InputModel {
        let userWalletModel: UserWalletModel
        let initialWalletModel: WalletModel
    }
}
