//
//  MarketsTokenDetailsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import UIKit
import TangemUI
import TangemStaking
import TangemLocalization
import struct TangemUIUtils.AlertBinder

final class MarketsTokenDetailsCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.tangemStoriesPresenter) private var tangemStoriesPresenter: any TangemStoriesPresenter
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.overlayContentStateController) private var bottomSheetStateController: OverlayContentStateController
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    @Published private(set) var presentationStyle: MarketsTokenDetailsPresentationStyle = .marketsSheet

    // MARK: - Root ViewModels

    @Published var rootViewModel: MarketsTokenDetailsViewModel? = nil
    @Published var error: AlertBinder? = nil

    // MARK: - Child ViewModels

    @Published var exchangesListViewModel: MarketsTokenDetailsExchangesListViewModel? = nil

    // MARK: - Child Coordinators

    @Published var sendCoordinator: SendCoordinator? = nil
    @Published var stakingDetailsCoordinator: StakingDetailsCoordinator? = nil
    @Published var yieldModulePromoCoordinator: YieldModulePromoCoordinator? = nil
    @Published var yieldModuleActiveCoordinator: YieldModuleActiveCoordinator? = nil
    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator? = nil
    @Published var newsPagerViewModel: NewsPagerViewModel? = nil
    @Published var newsRelatedTokenDetailsCoordinator: MarketsTokenDetailsCoordinator? = nil

    private var safariHandle: SafariHandle?

    private var isDeeplinkMode: Bool = false

    var isMarketsSheetFlow: Bool {
        presentationStyle == .marketsSheet
    }

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        presentationStyle = options.style
        isDeeplinkMode = options.isDeeplinkMode
        rootViewModel = .init(
            tokenInfo: options.info,
            presentationStyle: options.style,
            dataProvider: .init(),
            marketsQuotesUpdateHelper: CommonMarketsQuotesUpdateHelper(),
            coordinator: self
        )
    }

    private func resolvePresentationStyleForInnerFlow() -> MarketsTokenDetailsPresentationStyle {
        switch presentationStyle {
        case .marketsSheet, .addFundsSheet:
            return .marketsSheet

        // [REDACTED_USERNAME], if we're already in a fullScreenCover, navigationStack should be used for inner flows.
        case .navigationStack, .fullScreenCover:
            return .navigationStack
        }
    }
}

extension MarketsTokenDetailsCoordinator {
    struct Options {
        let info: MarketsTokenModel
        let style: MarketsTokenDetailsPresentationStyle
        let isDeeplinkMode: Bool

        init(info: MarketsTokenModel, style: MarketsTokenDetailsPresentationStyle, isDeeplinkMode: Bool = false) {
            self.info = info
            self.style = style
            self.isDeeplinkMode = isDeeplinkMode
        }
    }
}

extension MarketsTokenDetailsCoordinator: MarketsTokenDetailsRoutable {
    func openAppSettings() {
        UIApplication.openSystemSettings()
    }

    func openAccountsSelector(with model: MarketsTokenDetailsModel, walletDataProvider: MarketsWalletDataProvider) {
        let inputData = MarketsAddTokenFlowConfigurationFactory.InputData(
            coinId: model.id,
            coinName: model.name,
            coinSymbol: model.symbol,
            networks: model.availableNetworks
        )

        let configuration = MarketsAddTokenFlowConfigurationFactory.make(
            inputData: inputData,
            coordinator: self
        )

        if FeatureProvider.isAvailable(.redesign) {
            openRedesignedAddTokenFlow(
                inputData: inputData,
                configuration: configuration,
                walletDataProvider: walletDataProvider
            )
        } else {
            openLegacyAddTokenFlow(
                configuration: configuration,
                walletDataProvider: walletDataProvider
            )
        }
    }

    private func openRedesignedAddTokenFlow(
        inputData: MarketsAddTokenFlowConfigurationFactory.InputData,
        configuration: AddTokenFlowConfiguration,
        walletDataProvider: MarketsWalletDataProvider
    ) {
        guard let tokenItem = MarketsAddTokenFlowConfigurationFactory.makePreselectedTokenItem(
            inputData: inputData,
            userWalletModels: walletDataProvider.userWalletModels,
            isTokenAdded: configuration.isTokenAdded
        ) else {
            Task { @MainActor in
                self.presentErrorToast(with: Localization.commonSomethingWentWrong)
            }
            return
        }

        Task { @MainActor in
            guard let viewModel = AddTokenFlowRedesignedViewModel(
                tokenItem: tokenItem,
                userWalletModels: walletDataProvider.userWalletModels,
                configuration: configuration,
                coordinator: self
            ) else {
                self.presentErrorToast(with: Localization.commonSomethingWentWrong)
                return
            }
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    private func openLegacyAddTokenFlow(
        configuration: AddTokenFlowConfiguration,
        walletDataProvider: MarketsWalletDataProvider
    ) {
        Task { @MainActor in
            let viewModel = AddTokenFlowViewModel(
                userWalletModels: walletDataProvider.userWalletModels,
                configuration: configuration,
                coordinator: self
            )
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        let recipient = EmailConfig.default.recipient
        let mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: emailType)

        Task { @MainActor in
            mailPresenter.present(viewModel: mailViewModel)
        }
    }

    func openURL(_ url: URL) {
        safariManager.openURL(url)
    }

    func closeModule() {
        dismiss()
    }

    func openExchangesList(tokenId: String, numberOfExchangesListedOn: Int) {
        exchangesListViewModel = MarketsTokenDetailsExchangesListViewModel(
            tokenId: tokenId,
            numberOfExchangesListedOn: numberOfExchangesListedOn,
            presentationStyle: resolvePresentationStyleForInnerFlow(),
            exchangesListLoader: MarketsTokenDetailsDataProvider()
        ) { [weak self] in
            self?.exchangesListViewModel = nil
        }
    }

    func openStaking(input: SendInput, stakingManager: any StakingManager) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.stakingDetailsCoordinator = nil
        }

        let options = StakingDetailsCoordinator.Options(sendInput: input, manager: stakingManager)
        let coordinator = StakingDetailsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: options)
        stakingDetailsCoordinator = coordinator
    }

    func makeYieldModuleFlowFactory(input: SendInput, manager: YieldModuleManager) -> YieldModuleFlowFactory? {
        // [REDACTED_USERNAME]. Maintain the previous logic. Do not create factory if `multipleTransactionsSender` not found
        guard input.walletModel.multipleTransactionsSender != nil else {
            return nil
        }

        let factory = WalletModelTransactionDispatcherProvider(walletModel: input.walletModel, signer: input.userWalletInfo.signer)
        let dispatcher = factory.makeYieldModuleTransactionDispatcher()

        return CommonYieldModuleFlowFactory(
            walletModel: input.walletModel,
            yieldModuleManager: manager,
            transactionDispatcher: dispatcher
        )
    }

    func openYieldModulePromoView(apy: Decimal, factory: YieldModuleFlowFactory) {
        let dismissAction: Action<YieldModulePromoCoordinator.DismissOptions?> = { [weak self] option in
            self?.yieldModulePromoCoordinator = nil
            self?.proceedFeeCurrencyNavigatingDismissOption(option: option)
        }

        let coordinator = factory.makeYieldPromoCoordinator(apy: apy, isApyBoostPromo: false, dismissAction: dismissAction)
        yieldModulePromoCoordinator = coordinator
    }

    func openYieldModuleActiveInfo(factory: YieldModuleFlowFactory) {
        let dismissAction: Action<YieldModulePromoCoordinator.DismissOptions?> = { [weak self] option in
            self?.yieldModuleActiveCoordinator = nil
            self?.proceedFeeCurrencyNavigatingDismissOption(option: option)
        }

        let coordinator = factory.makeYieldActiveCoordinator(dismissAction: dismissAction)
        yieldModuleActiveCoordinator = coordinator
    }

    private func openMainTokenDetails(walletModel: any WalletModel) {
        guard let userWalletModel = userWalletRepository.selectedModel else {
            return
        }

        let dismissAction: Action<Void> = { [weak self] _ in
            self?.tokenDetailsCoordinator = nil
        }

        guard let coordinator = MarketsMainTokenDetailsCoordinatorFactory.make(
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        ) else {
            return
        }

        tokenDetailsCoordinator = coordinator
    }

    func openYield(input: SendInput, yieldModuleManager: any YieldModuleManager) {
        guard let factory = makeYieldModuleFlowFactory(input: input, manager: yieldModuleManager) else { return }

        let logger = CommonYieldAnalyticsLogger(tokenItem: input.walletModel.tokenItem, userWalletId: input.walletModel.userWalletId)

        func openActiveYield() {
            logger.logEarningApyClicked(state: .enabled)
            openYieldModuleActiveInfo(factory: factory)
        }

        func openPromoYield() {
            if let apy = yieldModuleManager.state?.marketInfo?.apy {
                openYieldModulePromoView(apy: apy, factory: factory)
                logger.logEarningApyClicked(state: .disabled)
            }
        }

        switch yieldModuleManager.state?.state {
        case .active:
            openActiveYield()
        case .failedToLoad(_, let cached?):
            switch cached {
            case .active:
                openActiveYield()
            case .notActive:
                openPromoYield()
            default:
                break
            }
        case .processing:
            openMainTokenDetails(walletModel: input.walletModel)
        case .notActive:
            openPromoYield()
        case .disabled, .failedToLoad, .loading, .none:
            break
        }
    }

    func shareTokenDetails(url: URL) {
        AppPresenter.shared.show(UIActivityViewController(activityItems: [url], applicationActivities: nil))
    }

    @MainActor
    func openInfoDialogue(title: String, message: String) {
        let viewModel = MarketsDescriptionDialogueViewModel(
            title: title,
            descriptionText: message,
            closeAction: { [weak self] in
                self?.floatingSheetPresenter.removeActiveSheet()
            }
        )
        floatingSheetPresenter.enqueue(sheet: viewModel)
    }

    @MainActor
    func openFullDescriptionDialogue(
        title: String,
        description: String,
        onGenerateAITapAction: @escaping () -> Void
    ) {
        let viewModel = MarketsDescriptionDialogueViewModel(
            title: title,
            descriptionText: description,
            showGeneratedWithAI: true,
            onGenerateAITapAction: { [weak self] in
                self?.floatingSheetPresenter.removeActiveSheet()
                // Floating sheet doesn't expose a dismiss animation completion callback,
                // so we use a delay to avoid presenting mail compose while the sheet is still animating out
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    onGenerateAITapAction()
                }
            },
            closeAction: { [weak self] in
                self?.floatingSheetPresenter.removeActiveSheet()
            }
        )
        floatingSheetPresenter.enqueue(sheet: viewModel)
    }

    @MainActor
    func openNews(newsIds: [Int], selectedIndex: Int) {
        let viewModel = NewsPagerViewModel(
            newsIds: newsIds,
            initialIndex: selectedIndex,
            isDeeplinkMode: false, // Always false - nested news screen should show back button, not close
            isMarketsSheetFlow: presentationStyle == .marketsSheet,
            dataSource: SingleNewsDataSource(),
            analyticsSource: .token,
            coordinator: self
        )
        newsPagerViewModel = viewModel
    }
}

// MARK: - AddFundsRoutable

extension MarketsTokenDetailsCoordinator: AddFundsRoutable {
    func addFundsRequestBuy(walletModel: any WalletModel, userWalletModel: any UserWalletModel) {
        let input = SendInput(userWalletInfo: userWalletModel.userWalletInfo, walletModel: walletModel)
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            openOnramp(input: input, parameters: .none)
        }
    }

    func addFundsRequestSwap(walletModel: any WalletModel, userWalletModel: any UserWalletModel) {
        let helper = SwapPredefinedParametersHelper()
        guard let parameters = helper.makeParameters(
            walletModel: walletModel,
            userWalletInfo: userWalletModel.userWalletInfo,
            position: .automatic
        ) else {
            return
        }

        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            openSwap(input: parameters, destination: walletModel.tokenItem)
        }
    }

    func addFundsRequestReceive(viewModel: ReceiveMainViewModel) {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func addFundsRequestGoToToken(walletModel: any WalletModel, userWalletModel: any UserWalletModel) {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            openPortfolioTokenDetails(walletModel: walletModel)
        }
    }

    func addFundsClose() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - MarketsPortfolioContainerRoutable

extension MarketsTokenDetailsCoordinator: MarketsPortfolioContainerRoutable {
    func openAddFunds(input: SendInput) {
        guard let userWalletModel = userWalletRepository.models.first(
            where: { $0.userWalletId == input.userWalletInfo.id }
        ) else {
            return
        }

        Task { @MainActor in
            let viewModel = AddFundsViewModel(
                input: .init(
                    mode: .sheet(.full),
                    primaryAction: .goToToken,
                    walletModel: input.walletModel,
                    userWalletModel: userWalletModel
                ),
                coordinator: self
            )

            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openReceive(userWalletInfo: UserWalletInfo, walletModel: any WalletModel) {
        let availabilityProvider = TokenActionAvailabilityProvider(userWalletInfo: userWalletInfo, walletModel: walletModel)
        if let unavailableAlert = TokenActionAvailabilityAlertBuilder().alert(
            for: availabilityProvider.receiveAvailability,
            blockchain: walletModel.tokenItem.blockchain
        ) {
            alertPresenter.present(alert: unavailableAlert)
            return
        }

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

    func openSwap(input: PredefinedSwapParameters, destination: TokenItem) {
        let action = { [weak self] in
            guard let self else { return }

            let dismissAction: Action<SendCoordinator.DismissOptions?> = { [weak self] option in
                self?.sendCoordinator = nil
                self?.proceedFeeCurrencyNavigatingDismissOption(option: option)
            }

            let openSwapBlock = { [weak self] in
                guard let self else { return }
                let coordinator = SendCoordinator(
                    dismissAction: dismissAction,
                    popToRootAction: popToRootAction
                )

                coordinator.start(with: .init(type: .swap(input), source: .markets))
                sendCoordinator = coordinator
            }

            tangemStoriesPresenter.present(
                story: .swap(.initialWithoutImages),
                analyticsSource: .markets,
                presentCompletion: openSwapBlock
            )
        }

        action()
    }

    func openOnramp(input: SendInput, parameters: PredefinedOnrampParameters) {
        let availabilityProvider = TokenActionAvailabilityProvider(userWalletInfo: input.userWalletInfo, walletModel: input.walletModel)
        guard availabilityProvider.isTopUpAvailable else {
            if let backupAlert = UserWalletBackupStatusHelper().alert(for: input.userWalletInfo) {
                alertPresenter.present(alert: backupAlert)
            }
            return
        }

        let dismissAction: Action<SendCoordinator.DismissOptions?> = { [weak self] _ in
            self?.sendCoordinator = nil
        }

        let sourceToken = CommonSendTransferableTokenFactory(
            userWalletInfo: input.userWalletInfo,
            walletModel: input.walletModel
        ).makeTransferableToken()

        let coordinator = SendCoordinator(dismissAction: dismissAction)
        let options = SendCoordinator.Options(type: .onramp(sourceToken, parameters: parameters), source: .markets)
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    @MainActor
    func openMatchedTokenList(
        walletModels: [any WalletModel],
        iconURL: URL,
        addTokenInputData: MarketsAddTokenFlowConfigurationFactory.InputData,
        walletDataProvider: MarketsWalletDataProvider
    ) {
        let portfolioViewModel = MarketsPortfolioTokenListViewModel(
            walletModels: walletModels,
            onSelect: { [weak self] walletModel in
                self?.openPortfolioTokenDetails(walletModel: walletModel)
            },
            coordinator: self
        )

        let flowViewModel = MarketsPortfolioFlowViewModel(portfolioViewModel: portfolioViewModel)

        portfolioViewModel.addTokenPromo = .init(iconURL: iconURL) { [weak self, weak flowViewModel] in
            guard let self, let flowViewModel else { return }
            showAddTokenFlow(
                in: flowViewModel,
                inputData: addTokenInputData,
                walletDataProvider: walletDataProvider
            )
        }

        floatingSheetPresenter.enqueue(sheet: flowViewModel)
    }

    @MainActor
    private func showAddTokenFlow(
        in flowViewModel: MarketsPortfolioFlowViewModel,
        inputData: MarketsAddTokenFlowConfigurationFactory.InputData,
        walletDataProvider: MarketsWalletDataProvider
    ) {
        let configuration = MarketsAddTokenFlowConfigurationFactory.make(inputData: inputData, coordinator: self)

        guard
            let tokenItem = MarketsAddTokenFlowConfigurationFactory.makePreselectedTokenItem(
                inputData: inputData,
                userWalletModels: walletDataProvider.userWalletModels,
                isTokenAdded: configuration.isTokenAdded
            ),
            let viewModel = AddTokenFlowRedesignedViewModel(
                tokenItem: tokenItem,
                userWalletModels: walletDataProvider.userWalletModels,
                configuration: configuration,
                coordinator: self
            )
        else {
            presentErrorToast(with: Localization.commonSomethingWentWrong)
            return
        }

        flowViewModel.showAddToken(viewModel)
    }

    func openAddFundsTokenList(walletModels: [any WalletModel], walletDataProvider: MarketsWalletDataProvider) {
        Task { @MainActor in
            weak var flowViewModelRef: MarketsPortfolioFlowViewModel?

            let portfolioViewModel = MarketsPortfolioTokenListViewModel(
                walletModels: walletModels,
                dismissesOnSelect: false,
                onSelect: { [weak self] walletModel in
                    guard let self, let flowViewModel = flowViewModelRef else { return }
                    showAddFunds(in: flowViewModel, walletModel: walletModel, walletDataProvider: walletDataProvider)
                },
                coordinator: self
            )

            let flowViewModel = MarketsPortfolioFlowViewModel(portfolioViewModel: portfolioViewModel)
            flowViewModelRef = flowViewModel

            floatingSheetPresenter.enqueue(sheet: flowViewModel)
        }
    }

    private func showAddFunds(
        in flowViewModel: MarketsPortfolioFlowViewModel,
        walletModel: any WalletModel,
        walletDataProvider: MarketsWalletDataProvider
    ) {
        guard let userWalletModel = walletDataProvider.userWalletModels[walletModel.userWalletId] else {
            return
        }

        Task { @MainActor in
            let viewModel = AddFundsViewModel(
                input: .init(
                    mode: .sheet(.full),
                    primaryAction: .goToToken,
                    walletModel: walletModel,
                    userWalletModel: userWalletModel
                ),
                coordinator: self
            )

            flowViewModel.showAddFunds(viewModel)
        }
    }

    private func openPortfolioTokenDetails(walletModel: any WalletModel) {
        guard
            let userWalletModel = userWalletRepository.models[walletModel.userWalletId],
            let account = walletModel.account
        else {
            return
        }

        let dismissAction: Action<Void> = { [weak self] _ in
            self?.tokenDetailsCoordinator = nil
        }

        let coordinator = TokenDetailsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
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
}

// MARK: - MarketsPortfolioTokenListRoutable

extension MarketsTokenDetailsCoordinator: MarketsPortfolioTokenListRoutable {
    func closePortfolioTokenList() {
        floatingSheetPresenter.removeActiveSheet()
    }
}

// MARK: - AddTokenFlowRoutable

extension MarketsTokenDetailsCoordinator: AddTokenFlowRoutable {
    func close() {
        floatingSheetPresenter.removeActiveSheet()
    }

    func presentSuccessToast(with text: String) {
        Toast(view: SuccessToast(text: text))
            .present(
                layout: .top(padding: ToastConstants.topPadding),
                type: .temporary()
            )
    }

    func presentErrorToast(with text: String) {
        Toast(view: WarningToast(text: text))
            .present(
                layout: .top(padding: ToastConstants.topPadding),
                type: .temporary()
            )
    }
}

// MARK: - Utilities functions

extension MarketsTokenDetailsCoordinator {
    func openBuyCrypto(at url: URL, with walletModel: any WalletModel) {
        safariHandle = safariManager.openURL(url) { [weak self] _ in
            self?.safariHandle = nil

            Task {
                try await Task.sleep(for: .seconds(1))
                await walletModel.update(silent: true, options: .balances)
            }
        }
    }
}

// MARK: - Constants

private extension MarketsTokenDetailsCoordinator {
    enum ToastConstants {
        static let topPadding: CGFloat = 52
    }
}

extension MarketsTokenDetailsCoordinator: FeeCurrencyNavigating {}

// MARK: - AddTokenFlowRedesignedRoutable

extension MarketsTokenDetailsCoordinator: AddTokenFlowRedesignedRoutable {}

// MARK: - NewsDetailsRoutable

extension MarketsTokenDetailsCoordinator: NewsDetailsRoutable {
    func dismissNewsDetails() {
        newsPagerViewModel = nil
    }

    func share(url: String) {
        guard let url = URL(string: url) else { return }
        AppPresenter.shared.show(UIActivityViewController(activityItems: [url], applicationActivities: nil))
    }

    func openTokenDetails(_ token: MarketsTokenModel) {
        let coordinator = MarketsTokenDetailsCoordinator(
            dismissAction: { [weak self] _ in
                self?.newsRelatedTokenDetailsCoordinator = nil
            },
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .init(info: token, style: resolvePresentationStyleForInnerFlow(), isDeeplinkMode: isDeeplinkMode))
        newsRelatedTokenDetailsCoordinator = coordinator
    }
}
