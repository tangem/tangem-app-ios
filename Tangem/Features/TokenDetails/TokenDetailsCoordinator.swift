//
//  TokenDetailsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class TokenDetailsCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - Root view model

    @Published private(set) var tokenDetailsViewModel: TokenDetailsViewModel? = nil

    // MARK: - Child coordinators

    @Published var sendCoordinator: SendCoordinator? = nil
    @Published var expressCoordinator: ExpressCoordinator? = nil
    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator? = nil
    @Published var stakingDetailsCoordinator: StakingDetailsCoordinator? = nil
    @Published var marketsTokenDetailsCoordinator: MarketsTokenDetailsCoordinator? = nil
    @Published var yieldModulePromoCoordinator: YieldModulePromoCoordinator? = nil
    @Published var yieldModuleActiveCoordinator: YieldModuleActiveCoordinator? = nil

    // MARK: - Child view models

    @Published var pendingExpressTxStatusBottomSheetViewModel: PendingExpressTxStatusBottomSheetViewModel? = nil

    @Injected(\.tangemStoriesPresenter) private var tangemStoriesPresenter: any TangemStoriesPresenter
    private var safariHandle: SafariHandle?

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let notificationManager = SingleTokenNotificationManager(
            userWalletId: options.userWalletInfo.id,
            walletModel: options.walletModel,
            walletModelsManager: options.walletModelsManager
        )

        let yieldModuleNoticeInteractor = YieldModuleNoticeInteractor()

        let tokenRouter = SingleTokenRouter(
            userWalletInfo: options.userWalletInfo,
            coordinator: self,
            yieldModuleNoticeInteractor: yieldModuleNoticeInteractor
        )

        let expressFactory = ExpressPendingTransactionsFactory(
            userWalletInfo: options.userWalletInfo,
            tokenItem: options.walletModel.tokenItem,
            walletModelUpdater: options.walletModel,
        )

        let pendingTransactionsManager = expressFactory.makePendingExpressTransactionsManager()

        let bannerNotificationManager: BannerNotificationManager? = {
            guard options.userWalletInfo.config.hasFeature(.multiCurrency) else {
                return nil
            }

            return BannerNotificationManager(
                userWalletInfo: options.userWalletInfo,
                placement: .tokenDetails(options.walletModel.tokenItem),
            )
        }()

        let factory = XPUBGeneratorFactory(cardInteractor: options.keysDerivingInteractor)
        let xpubGenerator = factory.makeXPUBGenerator(
            for: options.walletModel.tokenItem.blockchain,
            publicKey: options.walletModel.publicKey
        )

        tokenDetailsViewModel = .init(
            userWalletInfo: options.userWalletInfo,
            walletModel: options.walletModel,
            notificationManager: notificationManager,
            bannerNotificationManager: bannerNotificationManager,
            userTokensManager: options.userTokensManager,
            pendingExpressTransactionsManager: pendingTransactionsManager,
            xpubGenerator: xpubGenerator,
            coordinator: self,
            tokenRouter: tokenRouter,
            pendingTransactionDetails: options.pendingTransactionDetails
        )

        notificationManager.interactionDelegate = tokenDetailsViewModel
    }
}

// MARK: - Options

extension TokenDetailsCoordinator {
    struct Options {
        let userWalletInfo: UserWalletInfo
        let keysDerivingInteractor: any KeysDeriving
        let walletModelsManager: any WalletModelsManager
        let userTokensManager: any UserTokensManager
        let walletModel: any WalletModel
        /// Initialized when a deeplink is received for an onramp or exchange (swap) status update related to a specific transaction
        let pendingTransactionDetails: PendingTransactionDetails?

        /// Legacy
        /// Will be removed in [REDACTED_INFO]
        init(
            userWalletModel: any UserWalletModel,
            walletModel: any WalletModel,
            pendingTransactionDetails: PendingTransactionDetails? = nil
        ) {
            userWalletInfo = userWalletModel.userWalletInfo
            keysDerivingInteractor = userWalletModel.keysDerivingInteractor
            walletModelsManager = userWalletModel.walletModelsManager // accounts_fixes_needed_none
            userTokensManager = userWalletModel.userTokensManager // accounts_fixes_needed_none
            self.walletModel = walletModel
            self.pendingTransactionDetails = pendingTransactionDetails
        }

        init(
            userWalletInfo: UserWalletInfo,
            keysDerivingInteractor: any KeysDeriving,
            walletModelsManager: any WalletModelsManager,
            userTokensManager: any UserTokensManager,
            walletModel: any WalletModel,
            pendingTransactionDetails: PendingTransactionDetails?
        ) {
            self.userWalletInfo = userWalletInfo
            self.keysDerivingInteractor = keysDerivingInteractor
            self.walletModelsManager = walletModelsManager
            self.userTokensManager = userTokensManager
            self.walletModel = walletModel
            self.pendingTransactionDetails = pendingTransactionDetails
        }
    }
}

// MARK: - TokenDetailsRoutable

extension TokenDetailsCoordinator: TokenDetailsRoutable {
    func openYieldModulePromoView(apy: Decimal, factory: YieldModuleFlowFactory) {
        let dismissAction: Action<YieldModulePromoCoordinator.DismissOptions?> = { [weak self] option in
            self?.yieldModulePromoCoordinator = nil
            self?.proceedFeeCurrencyNavigatingDismissOption(option: option)
        }

        let coordinator = factory.makeYieldPromoCoordinator(apy: apy, dismissAction: dismissAction)
        yieldModulePromoCoordinator = coordinator
    }

    func openYieldModuleActiveInfo(factory: YieldModuleFlowFactory) {
        let dismissAction: Action<YieldModuleActiveCoordinator.DismissOptions?> = { [weak self] option in
            self?.yieldModuleActiveCoordinator = nil
            self?.proceedFeeCurrencyNavigatingDismissOption(option: option)
        }

        let coordinator = factory.makeYieldActiveCoordinator(dismissAction: dismissAction)
        yieldModuleActiveCoordinator = coordinator
    }

    func openYieldBalanceInfo(factory: YieldModuleFlowFactory) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: factory.makeYieldModuleBalanceInfoViewModel())
        }
    }
}

// MARK: - PendingExpressTxStatusRoutable

extension TokenDetailsCoordinator: PendingExpressTxStatusRoutable {
    func openURL(_ url: URL) {
        safariManager.openURL(url)
    }

    func openRefundCurrency(walletModel: any WalletModel, userWalletModel: any UserWalletModel) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.tokenDetailsCoordinator = nil
        }

        let coordinator = TokenDetailsCoordinator(dismissAction: dismissAction)
        coordinator.start(
            with: .init(userWalletModel: userWalletModel, walletModel: walletModel)
        )

        tokenDetailsCoordinator = coordinator
    }

    func dismissPendingTxSheet() {
        pendingExpressTxStatusBottomSheetViewModel = nil
    }
}

extension TokenDetailsCoordinator: SingleTokenBaseRoutable {
    func openReceiveScreen(walletModel: any WalletModel) {
        let receiveFlowFactory = AvailabilityReceiveFlowFactory(
            flow: .crypto,
            tokenItem: walletModel.tokenItem,
            addressTypesProvider: walletModel,
            // [REDACTED_TODO_COMMENT]
            isYieldModuleActive: false
        )

        let viewModel = receiveFlowFactory.makeAvailabilityReceiveFlow()

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openSellCrypto(at url: URL, action: @escaping (String) -> Void) {
        Analytics.log(.withdrawScreenOpened)

        safariHandle = safariManager.openURL(url) { [weak self] closeURL in
            self?.safariHandle = nil
            action(closeURL.absoluteString)
        }
    }

    func openSend(input: SendInput) {
        guard SendFeatureProvider.shared.isAvailable else {
            return
        }

        let coordinator = makeSendCoordinator()
        let options = SendCoordinator.Options(input: input, type: .send, source: .main)
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openSendToSell(input: SendInput, sellParameters: PredefinedSellParameters) {
        guard SendFeatureProvider.shared.isAvailable else {
            return
        }

        let coordinator = makeSendCoordinator()

        let options = SendCoordinator.Options(
            input: input,
            type: .sell(parameters: sellParameters),
            source: .tokenDetails
        )
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openExpress(input: ExpressDependenciesInput) {
        let factory = CommonExpressModulesFactory(input: input)
        let coordinator = makeExpressCoordinator(factory: factory)

        let showExpressBlock = { [weak self] in
            coordinator.start(with: .default)
            self?.expressCoordinator = coordinator
        }

        Task { @MainActor [tangemStoriesPresenter] in
            tangemStoriesPresenter.present(
                story: .swap(.initialWithoutImages),
                analyticsSource: .token,
                presentCompletion: showExpressBlock
            )
        }
    }

    func openStaking(options: StakingDetailsCoordinator.Options) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.stakingDetailsCoordinator = nil
        }

        let coordinator = StakingDetailsCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )

        coordinator.start(with: options)
        stakingDetailsCoordinator = coordinator
    }

    func openInSafari(url: URL) {
        safariManager.openURL(url)
    }

    func openMarketsTokenDetails(tokenModel: MarketsTokenModel) {
        let coordinator = MarketsTokenDetailsCoordinator()
        coordinator.start(with: .init(info: tokenModel, style: .defaultNavigationStack))
        marketsTokenDetailsCoordinator = coordinator
    }

    func openOnramp(input: SendInput, parameters: PredefinedOnrampParameters) {
        let coordinator = makeSendCoordinator()
        let options = SendCoordinator.Options(
            input: input,
            type: .onramp(parameters: parameters),
            source: .tokenDetails
        )
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openPendingExpressTransactionDetails(
        pendingTransaction: PendingTransaction,
        tokenItem: TokenItem,
        userWalletInfo: UserWalletInfo,
        pendingTransactionsManager: PendingExpressTransactionsManager
    ) {
        pendingExpressTxStatusBottomSheetViewModel = PendingExpressTxStatusBottomSheetViewModel(
            pendingTransaction: pendingTransaction,
            currentTokenItem: tokenItem,
            userWalletInfo: userWalletInfo,
            pendingTransactionsManager: pendingTransactionsManager,
            router: self
        )
    }
}

// MARK: - SendFeeCurrencyNavigating, ExpressFeeCurrencyNavigating

extension TokenDetailsCoordinator: SendFeeCurrencyNavigating, ExpressFeeCurrencyNavigating {}
