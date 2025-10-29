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

    // MARK: - Child view models

    @Published var receiveBottomSheetViewModel: ReceiveBottomSheetViewModel? = nil
    @Published var pendingExpressTxStatusBottomSheetViewModel: PendingExpressTxStatusBottomSheetViewModel? = nil

    @Injected(\.tangemStoriesPresenter) private var tangemStoriesPresenter: any TangemStoriesPresenter
    private var safariHandle: SafariHandle?
    private var options: Options?

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        self.options = options

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
            walletModel: options.walletModel,
            userTokensManager: options.userTokensManager,
        )

        let pendingTransactionsManager = expressFactory.makePendingExpressTransactionsManager()

        let bannerNotificationManager: BannerNotificationManager? = {
            guard options.userWalletInfo.config.hasFeature(.multiCurrency) else {
                return nil
            }

            return BannerNotificationManager(
                userWalletInfo: options.userWalletInfo,
                walletModelsManager: options.walletModelsManager,
                placement: .tokenDetails(options.walletModel.tokenItem)
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
            userTokensManager: options.userTokensManager,
            walletModelsManager: options.walletModelsManager,
            notificationManager: notificationManager,
            bannerNotificationManager: bannerNotificationManager,
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
    func openYieldModulePromoView(walletModel: any WalletModel, apy: Decimal, signer: any TangemSigner) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.yieldModulePromoCoordinator = nil
        }

        guard let factory = YieldModuleFlowFactory(
            walletModel: walletModel,
            apy: apy,
            signer: signer,
            feeCurrencyNavigator: self,
            dismissAction: dismissAction
        ) else {
            return
        }

        let coordinator = factory.getYieldPromoCoordinator()
        yieldModulePromoCoordinator = coordinator
    }

    func openYieldEarnInfo(walletModel: any WalletModel, signer: any TangemSigner) {
        guard
            let factory = YieldModuleFlowFactory(
                walletModel: walletModel,
                signer: signer,
                feeCurrencyNavigator: self,
                dismissAction: dismissAction
            ),
            let vm = factory.makeYieldInfoViewModel()
        else {
            return
        }

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: vm)
        }
    }

    func openYieldBalanceInfo(tokenName: String, tokenId: String?) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: YieldModuleBalanceInfoViewModel(tokenName: tokenName, tokenId: tokenId))
        }
    }
}

// MARK: - PendingExpressTxStatusRoutable

extension TokenDetailsCoordinator: PendingExpressTxStatusRoutable {
    func openURL(_ url: URL) {
        safariManager.openURL(url)
    }

    func openCurrency(tokenItem: TokenItem, userWalletInfo: UserWalletInfo) {}

    func openCurrency(tokenItem: TokenItem, userWalletModel: UserWalletModel) {
        pendingExpressTxStatusBottomSheetViewModel = nil

        // We don't have info about derivation here, so we have to find first non-custom walletModel.
        guard let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: {
            $0.tokenItem.blockchain == tokenItem.blockchain
                && $0.tokenItem.token == tokenItem.token
                && !$0.isCustom
        }) else {
            return
        }

        openTokenDetails(for: walletModel)
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

        switch receiveFlowFactory.makeAvailabilityReceiveFlow() {
        case .bottomSheetReceiveFlow(let viewModel):
            receiveBottomSheetViewModel = viewModel
        case .domainReceiveFlow(let viewModel):
            Task { @MainActor in
                floatingSheetPresenter.enqueue(sheet: viewModel)
            }
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
        pendingTransactionsManager: any PendingExpressTransactionsManager
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

// MARK: - SendFeeCurrencyNavigating, ExpressFeeCurrencyNavigating protocol conformance

extension TokenDetailsCoordinator: SendFeeCurrencyNavigating, ExpressFeeCurrencyNavigating {
    // [REDACTED_TODO_COMMENT]
    /// - Note: This coordinator uses a custom implementation of the `SendFeeCurrencyNavigating.openFeeCurrency(for:userWalletModel:)` method.
    func openFeeCurrency(for model: any WalletModel, userWalletModel: UserWalletModel) {
        openTokenDetails(for: model)
    }
}

// MARK: - Private

private extension TokenDetailsCoordinator {
    func openTokenDetails(for walletModel: any WalletModel) {
        guard let options = options, walletModel.tokenItem != options.walletModel.tokenItem else {
            return
        }

        let dismissAction: Action<Void> = { [weak self] _ in
            self?.tokenDetailsCoordinator = nil
        }

        let coordinator = TokenDetailsCoordinator(dismissAction: dismissAction)
        coordinator.start(
            with: .init(
                userWalletInfo: options.userWalletInfo,
                walletModelsManager: options.walletModelsManager,
                walletModel: walletModel
            )
        )

        tokenDetailsCoordinator = coordinator
    }
}
