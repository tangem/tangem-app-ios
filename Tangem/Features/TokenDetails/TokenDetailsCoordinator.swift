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
import UIKit

final class TokenDetailsCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - Root view model

    @Published private(set) var tokenDetailsViewModel: TokenDetailsViewModel? = nil

    // MARK: - Child coordinators

    @Published var sendCoordinator: SendCoordinator? = nil
    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator? = nil
    @Published var stakingDetailsCoordinator: StakingDetailsCoordinator? = nil
    @Published var marketsTokenDetailsCoordinator: MarketsTokenDetailsCoordinator? = nil
    @Published var yieldModulePromoCoordinator: YieldModulePromoCoordinator? = nil
    @Published var yieldModuleActiveCoordinator: YieldModuleActiveCoordinator? = nil

    // MARK: - Child view models

    @Published var pendingExpressTxStatusBottomSheetViewModel: PendingExpressTxStatusBottomSheetViewModel? = nil
    @Published var dynamicAddressesEnterViewModel: DynamicAddressesEnterViewModel? = nil

    @Injected(\.tangemStoriesPresenter) private var tangemStoriesPresenter: any TangemStoriesPresenter
    private var safariHandle: SafariHandle?

    let isRedesign: Bool = FeatureProvider.isAvailable(.redesign)

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let notificationManager = SingleTokenNotificationManager(
            userWalletId: options.userWalletInfo.id,
            walletModel: options.walletModel,
            walletModelsManager: options.walletModelsManager,
            tangemIconProvider: CommonTangemIconProvider(config: options.userWalletInfo.config)
        )

        let tokenRouter = SingleTokenRouter(
            userWalletInfo: options.userWalletInfo,
            coordinator: self
        )

        let expressFactory = ExpressStatusTrackingFactory(
            userWalletInfo: options.userWalletInfo,
            tokenItem: options.walletModel.tokenItem,
            walletModelUpdater: options.walletModel,
            transactionHistoryEnricherFactory: { [weak walletModel = options.walletModel] in
                try? await walletModel?
                    .featuresPublisher
                    .first()
                    .async()
                    .transactionHistoryProvider
            }
        )

        let expressStatusTracking = expressFactory.makeExpressStatusTracking()

        let factory = XPUBGeneratorFactory(cardInteractor: options.keysDerivingInteractor)
        let xpubGenerator = factory.makeXPUBGenerator(
            for: options.walletModel.tokenItem.blockchain,
            publicKey: options.walletModel.publicKey
        )

        let deeplinkHandler = TokenDetailsDeeplinkHandler(
            coordinator: self,
            walletModel: options.walletModel,
            userWalletInfo: options.userWalletInfo
        )

        tokenDetailsViewModel = .init(
            userWalletInfo: options.userWalletInfo,
            walletModel: options.walletModel,
            notificationManager: notificationManager,
            userTokensManager: options.userTokensManager,
            pendingExpressTransactionsManager: expressStatusTracking.manager,
            expressStatusPollingHelper: expressStatusTracking.pollingHelper,
            xpubGenerator: xpubGenerator,
            coordinator: self,
            tokenRouter: tokenRouter,
            pendingTransactionDetails: options.pendingTransactionDetails,
            deeplinkHandler: deeplinkHandler,
            presentSource: options.presentSource
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
        let presentSource: TokenDetailsPresentSource

        init(
            userWalletInfo: UserWalletInfo,
            keysDerivingInteractor: any KeysDeriving,
            walletModelsManager: any WalletModelsManager,
            userTokensManager: any UserTokensManager,
            walletModel: any WalletModel,
            pendingTransactionDetails: PendingTransactionDetails? = nil,
            presentSource: TokenDetailsPresentSource = .navigation
        ) {
            self.userWalletInfo = userWalletInfo
            self.keysDerivingInteractor = keysDerivingInteractor
            self.walletModelsManager = walletModelsManager
            self.userTokensManager = userTokensManager
            self.walletModel = walletModel
            self.pendingTransactionDetails = pendingTransactionDetails
            self.presentSource = presentSource
        }
    }
}

// MARK: - TokenDetailsRoutable

extension TokenDetailsCoordinator: TokenDetailsRoutable {
    func openYieldModulePromoView(apy: Decimal, isApyBoostPromo: Bool, factory: YieldModuleFlowFactory) {
        let dismissAction: Action<YieldModulePromoCoordinator.DismissOptions?> = { [weak self] option in
            self?.yieldModulePromoCoordinator = nil
            self?.proceedFeeCurrencyNavigatingDismissOption(option: option)
        }

        let coordinator = factory.makeYieldPromoCoordinator(
            apy: apy,
            isApyBoostPromo: isApyBoostPromo,
            dismissAction: dismissAction
        )
        yieldModulePromoCoordinator = coordinator
    }

    func openYieldApyBoostStory(apy: Decimal, factory: YieldModuleFlowFactory) {
        Task { @MainActor [tangemStoriesPresenter] in
            tangemStoriesPresenter.present(
                story: .yieldFirstActivationAPYBoostStory,
                analyticsSource: .token,
                presentCompletion: { [weak self] in
                    self?.openYieldModulePromoView(apy: apy, isApyBoostPromo: true, factory: factory)
                }
            )
        }
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

    func openCloreMigration(factory: CloreMigrationModuleFlowFactory) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: factory.makeCloreMigrationViewModel())
        }
    }

    func openDynamicAddressesEnterView(
        walletModelDynamicAddressesProvider: WalletModelDynamicAddressesProvider,
        analyticsLogger: DynamicAddressesAnalyticsLogger
    ) {
        dynamicAddressesEnterViewModel = DynamicAddressesEnterViewModel(
            walletModelDynamicAddressesProvider: walletModelDynamicAddressesProvider,
            analyticsLogger: analyticsLogger,
            coordinator: self
        )
    }

    func openDynamicAddressesUnavailableSheet(messageType: DynamicAddressesUnavailableSheetViewModel.MessageType) {
        let viewModel = DynamicAddressesUnavailableSheetViewModel(messageType: messageType, coordinator: self)
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openStakingRegionUnavailableSheet() {
        let viewModel = StakingRegionUnavailableSheetViewModel(coordinator: self)
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openDynamicAddressesDisableSheet(
        walletModelDynamicAddressesProvider: WalletModelDynamicAddressesProvider,
        compoundFlowBaseDependenciesFactory: DynamicAddressesCompoundFlowBaseDependenciesFactory,
        analyticsLogger: DynamicAddressesAnalyticsLogger
    ) {
        let viewModel = DynamicAddressesDisableSheetViewModel(
            walletModelDynamicAddressesProvider: walletModelDynamicAddressesProvider,
            compoundFlowBaseDependenciesFactory: compoundFlowBaseDependenciesFactory,
            analyticsLogger: analyticsLogger,
            coordinator: self
        )
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openURLInSystemBrowser(url: URL) {
        UIApplication.shared.open(url)
    }
}

// MARK: - DynamicAddressesEnterRoutable

extension TokenDetailsCoordinator: DynamicAddressesEnterRoutable {
    func closeDynamicAddressesEnterView() {
        dynamicAddressesEnterViewModel = nil
    }
}

// MARK: - DynamicAddressesUnavailableSheetRoutable

extension TokenDetailsCoordinator: DynamicAddressesUnavailableSheetRoutable {
    func closeDynamicAddressesUnavailableSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - DynamicAddressesDisableSheetRoutable

extension TokenDetailsCoordinator: DynamicAddressesDisableSheetRoutable {
    func closeDynamicAddressesDisableSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - StakingRegionUnavailableSheetRoutable

extension TokenDetailsCoordinator: StakingRegionUnavailableSheetRoutable {
    func closeStakingRegionUnavailableSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
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

        guard let account = walletModel.account else {
            let message = "Inconsistent state: WalletModel '\(walletModel.name)' has no account in accounts-enabled build"
            AppLogger.error(error: message)
            assertionFailure(message)
            return
        }

        coordinator.start(
            with: .init(
                userWalletInfo: userWalletModel.userWalletInfo,
                keysDerivingInteractor: userWalletModel.keysDerivingInteractor,
                walletModelsManager: account.walletModelsManager,
                userTokensManager: account.userTokensManager,
                walletModel: walletModel
            )
        )

        tokenDetailsCoordinator = coordinator
    }

    func dismissPendingTxSheet() {
        pendingExpressTxStatusBottomSheetViewModel = nil
    }
}

extension TokenDetailsCoordinator: SingleTokenBaseRoutable {
    func openTransactionDetails(_ data: TransactionDetailsRouteData) {
        Task { @MainActor in
            let context = TransactionDetailsFactory.Context(
                tokenIconInfo: data.tokenIconInfo,
                tokenSymbol: data.tokenSymbol,
                tokenCurrencyId: data.tokenCurrencyId,
                receiverName: data.receiverName,
                receiverAccountIcon: data.receiverAccountIcon,
                openExplorer: data.walletModel.exploreTransactionURL(for: data.transaction.hash).map { url in
                    { [weak self] in
                        self?.floatingSheetPresenter.removeActiveSheet()
                        self?.openInSafari(url: url)
                    }
                },
                openURL: { [weak self] url in
                    self?.floatingSheetPresenter.removeActiveSheet()
                    self?.openInSafari(url: url)
                },
                share: { [weak self] text in
                    self?.floatingSheetPresenter.removeActiveSheet()
                    AppPresenter.shared.show(UIActivityViewController(activityItems: [text], applicationActivities: nil))
                },
                onClose: { [weak self] in self?.floatingSheetPresenter.removeActiveSheet() }
            )

            let viewModel = TransactionDetailsFactory().makeViewModel(
                transaction: data.transaction,
                record: data.record,
                context: context,
                recordUpdates: data.recordUpdates
            )

            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openReceiveScreen(walletModel: any WalletModel) {
        let receiveFlowFactory = AvailabilityReceiveFlowFactory(
            flow: .crypto,
            tokenItem: walletModel.tokenItem,
            addressTypesProvider: walletModel
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

        let sourceToken = CommonSendSwapableTokenFactory(
            userWalletInfo: input.userWalletInfo,
            walletModel: input.walletModel,
            operationType: .swapAndSend
        ).makeSwapableToken()

        let coordinator = makeSendCoordinator()
        let options = SendCoordinator.Options(type: .send(sourceToken), source: .tokenDetails)
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openSwap(parameters: PredefinedSwapParameters) {
        let coordinator = makeSendCoordinator()
        let options = SendCoordinator.Options(type: .swap(parameters), source: .tokenDetails)

        Task { @MainActor [tangemStoriesPresenter] in
            tangemStoriesPresenter.present(
                story: .swap(.initialWithoutImages),
                analyticsSource: .token,
                presentCompletion: { [weak self] in
                    coordinator.start(with: options)
                    self?.sendCoordinator = coordinator
                }
            )
        }
    }

    func openSendToSell(input: SendInput, sellParameters: PredefinedSellParameters) {
        guard SendFeatureProvider.shared.isAvailable else {
            return
        }

        let sourceToken = CommonSendTransferableTokenFactory(
            userWalletInfo: input.userWalletInfo,
            walletModel: input.walletModel
        ).makeTransferableToken()

        let coordinator = makeSendCoordinator()
        let options = SendCoordinator.Options(
            type: .sell(sourceToken, parameters: sellParameters),
            source: .tokenDetails
        )
        coordinator.start(with: options)
        sendCoordinator = coordinator
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
        let coordinator = MarketsTokenDetailsCoordinator(
            dismissAction: { [weak self] in
                self?.marketsTokenDetailsCoordinator = nil
            }
        )

        let presentationStyle: MarketsTokenDetailsPresentationStyle = isRedesign ? .fullScreenCover : .navigationStack

        coordinator.start(with: .init(info: tokenModel, style: presentationStyle))
        marketsTokenDetailsCoordinator = coordinator
    }

    func openOnramp(input: SendInput, parameters: PredefinedOnrampParameters) {
        let sourceToken = CommonSendTransferableTokenFactory(
            userWalletInfo: input.userWalletInfo,
            walletModel: input.walletModel
        ).makeTransferableToken()

        let coordinator = makeSendCoordinator()
        let options = SendCoordinator.Options(
            type: .onramp(sourceToken, parameters: parameters),
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

// MARK: - SendFeeCurrencyNavigating

extension TokenDetailsCoordinator: SendFeeCurrencyNavigating {}
