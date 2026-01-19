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
    @Injected(\.expressPairsRepository)
    private var expressPairsRepository: ExpressPairsRepository

    private let initialWalletModel: any WalletModel = CommonWalletModel.mockETH
    private let userWalletModel: UserWalletModel = UserWalletModelMock()
    private let expressAPIProviderFactory = ExpressAPIProviderFactory()

    private lazy var pendingTransactionRepository = ExpressPendingTransactionRepositoryMock()
    private lazy var expressInteractor = makeExpressInteractor()
    private lazy var expressAPIProvider = makeExpressAPIProvider()
    private lazy var expressRepository = makeExpressRepository()

    private var userWalletInfo: UserWalletInfo { userWalletModel.userWalletInfo }

    func makeExpressViewModel(coordinator: ExpressRoutable) -> ExpressViewModel {
        let notificationManager = notificationManager
        let model = ExpressViewModel(
            userWalletInfo: userWalletModel.userWalletInfo,
            initialTokenItem: initialWalletModel.tokenItem,
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
            userWalletInfo: userWalletModel.userWalletInfo
        )
    }

    func makeSwapTokenSelectorViewModel(
        swapDirection: SwapTokenSelectorViewModel.SwapDirection,
        coordinator: any SwapTokenSelectorRoutable
    ) -> SwapTokenSelectorViewModel {
        SwapTokenSelectorViewModel(
            swapDirection: swapDirection,
            tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel(walletsProvider: .common(), availabilityProvider: .swap()),
            expressInteractor: expressInteractor,
            coordinator: coordinator
        )
    }

    func makeFeeSelectorViewModel(
        coordinator: SendFeeSelectorRoutable
    ) -> SendFeeSelectorViewModel? {
        fatalError()
    }

    func makeExpressApproveViewModel(
        source: any ExpressInteractorSourceWallet,
        providerName: String,
        selectedPolicy: BSDKApprovePolicy,
        coordinator: any ExpressApproveRoutable
    ) -> ExpressApproveViewModel {
        ExpressApproveViewModel(
            input: .init(
                settings: .init(
                    subtitle: Localization.givePermissionSwapSubtitle(providerName, "USDT"),
                    feeFooterText: Localization.swapGivePermissionFeeFooter,
                    tokenItem: .token(.tetherMock, .init(.ethereum(testnet: false), derivationPath: .none)),
                    feeTokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: .none)),
                    selectedPolicy: selectedPolicy,
                    tangemIconProvider: CommonTangemIconProvider(config: userWalletModel.config)
                ),
                feeFormatter: feeFormatter,
                approveViewModelInput: expressInteractor,
            ),
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
            initialTokenItem: initialWalletModel.tokenItem,
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
                tokenItem: initialWalletModel.tokenItem,
                walletModelUpdater: initialWalletModel,
                expressAPIProvider: makeExpressAPIProvider(),
                expressRefundedTokenHandler: ExpressRefundedTokenHandlerMock()
            ),
            second: CommonPendingOnrampTransactionsManager(
                userWalletId: userWalletModel.userWalletId.stringValue,
                tokenItem: initialWalletModel.tokenItem,
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
        ExpressNotificationManager(
            userWalletId: userWalletModel.userWalletId,
            expressInteractor: expressInteractor
        )
    }

    var priceChangeFormatter: PriceChangeFormatter { .init() }
    var balanceConverter: BalanceConverter { .init() }
    var balanceFormatter: BalanceFormatter { .init() }
    var providerFormatter: ExpressProviderFormatter { .init(balanceFormatter: balanceFormatter) }
    var userWalletId: String { userWalletModel.userWalletId.stringValue }
    var signer: TangemSigner { CardSigner(filter: .cardId(""), sdk: TangemSdkDefaultFactory().makeTangemSdk(), twinKey: nil) }

    var expressTokensListAdapter: ExpressTokensListAdapter {
        CommonExpressTokensListAdapter(userWalletId: userWalletInfo.id)
    }

    var expressDestinationService: ExpressDestinationService {
        CommonExpressDestinationService(userWalletId: userWalletInfo.id)
    }

    // MARK: - Methods

    func makeExpressAPIProvider() -> ExpressAPIProvider {
        expressAPIProviderFactory.makeExpressAPIProvider(
            userWalletId: userWalletModel.userWalletId,
            refcode: userWalletModel.refcodeProvider?.getRefcode()
        )
    }

    func makeExpressInteractor() -> ExpressInteractor {
        let transactionValidator = ExpressProviderTransactionValidatorMock()

        let expressManager = TangemExpressFactory().makeExpressManager(
            expressAPIProvider: expressAPIProvider,
            expressRepository: expressRepository,
            transactionValidator: transactionValidator
        )

        let sender = ExpressInteractorWalletModelWrapper(
            userWalletInfo: userWalletInfo,
            walletModel: initialWalletModel,
            expressOperationType: .swap
        )

        let interactor = ExpressInteractor(
            userWalletInfo: userWalletInfo,
            swappingPair: .init(sender: .success(sender), destination: .loading),
            expressManager: expressManager,
            expressPairsRepository: expressPairsRepository,
            expressPendingTransactionRepository: pendingTransactionRepository,
            expressDestinationService: expressDestinationService,
            expressAPIProvider: expressAPIProvider,
        )

        return interactor
    }

    func makeExpressRepository() -> ExpressRepository {
        CommonExpressRepository(expressAPIProvider: expressAPIProvider)
    }
}
