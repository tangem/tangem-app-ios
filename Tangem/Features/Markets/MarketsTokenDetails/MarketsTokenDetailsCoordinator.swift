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

    // MARK: - Root ViewModels

    @Published var rootViewModel: MarketsTokenDetailsViewModel? = nil
    @Published var error: AlertBinder? = nil

    // MARK: - Child ViewModels

    @Published var exchangesListViewModel: MarketsTokenDetailsExchangesListViewModel? = nil

    // MARK: - Child Coordinators

    @Published var tokenNetworkSelectorCoordinator: MarketsTokenNetworkSelectorCoordinator? = nil
    @Published var sendCoordinator: SendCoordinator? = nil
    @Published var expressCoordinator: ExpressCoordinator? = nil
    @Published var stakingDetailsCoordinator: StakingDetailsCoordinator? = nil
    @Published var yieldModulePromoCoordinator: YieldModulePromoCoordinator? = nil
    @Published var yieldModuleActiveCoordinator: YieldModuleActiveCoordinator? = nil
    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator? = nil
    @Published var newsPagerViewModel: NewsPagerViewModel? = nil
    @Published var newsRelatedTokenDetailsCoordinator: MarketsTokenDetailsCoordinator? = nil

    private var safariHandle: SafariHandle?
    private let yieldModuleNoticeInteractor = YieldModuleNoticeInteractor()
    private var presentationStyle: MarketsTokenDetailsPresentationStyle = .marketsSheet
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
    func openTokenSelector(with model: MarketsTokenDetailsModel, walletDataProvider: MarketsWalletDataProvider) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.tokenNetworkSelectorCoordinator = nil
        }

        tokenNetworkSelectorCoordinator = MarketsTokenNetworkSelectorCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        tokenNetworkSelectorCoordinator?.start(
            with: .init(
                inputData: .init(coinId: model.id, coinName: model.name, coinSymbol: model.symbol, networks: model.availableNetworks),
                walletDataProvider: walletDataProvider
            )
        )
    }

    func openAccountsSelector(with model: MarketsTokenDetailsModel, walletDataProvider: MarketsWalletDataProvider) {
        let inputData = MarketsTokensNetworkSelectorViewModel.InputData(
            coinId: model.id,
            coinName: model.name,
            coinSymbol: model.symbol,
            networks: model.availableNetworks
        )

        let configuration = MarketsAddTokenFlowConfigurationFactory.make(
            inputData: inputData,
            coordinator: self
        )

        let viewModel = AccountsAwareAddTokenFlowViewModel(
            userWalletModels: walletDataProvider.userWalletModels,
            configuration: configuration,
            coordinator: self
        )

        Task { @MainActor in
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

    func openExchangesList(tokenId: String, numberOfExchangesListedOn: Int, presentationStyle: MarketsTokenDetailsPresentationStyle) {
        exchangesListViewModel = MarketsTokenDetailsExchangesListViewModel(
            tokenId: tokenId,
            numberOfExchangesListedOn: numberOfExchangesListedOn,
            presentationStyle: presentationStyle,
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
        let factory = TransactionDispatcherFactory(walletModel: input.walletModel, signer: input.userWalletInfo.signer)
        guard let dispatcher = factory.makeYieldModuleDispatcher() else {
            return nil
        }

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

        let coordinator = factory.makeYieldPromoCoordinator(apy: apy, dismissAction: dismissAction)
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

// MARK: - MarketsPortfolioContainerRoutable

extension MarketsTokenDetailsCoordinator: MarketsPortfolioContainerRoutable {
    func openReceive(walletModel: any WalletModel) {
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

    func openExchange(input: ExpressDependenciesInput) {
        let action = { [weak self] in
            guard let self else { return }

            let dismissAction: ExpressCoordinator.DismissAction = { [weak self] option in
                self?.expressCoordinator = nil
                self?.proceedFeeCurrencyNavigatingDismissOption(option: option)
            }

            let openSwapBlock = { [weak self] in
                guard let self else { return }
                Task { @MainActor in
                    let factory = CommonExpressModulesFactory(input: input)
                    let coordinator = ExpressCoordinator(
                        factory: factory,
                        dismissAction: dismissAction,
                        popToRootAction: self.popToRootAction
                    )

                    coordinator.start(with: .default)
                    self.expressCoordinator = coordinator
                }
            }

            Task { @MainActor [tangemStoriesPresenter] in
                tangemStoriesPresenter.present(
                    story: .swap(.initialWithoutImages),
                    analyticsSource: .markets,
                    presentCompletion: openSwapBlock
                )
            }
        }

        if yieldModuleNoticeInteractor.shouldShowYieldModuleAlert(for: input.source.tokenItem) {
            openViaYieldNotice(tokenItem: input.source.tokenItem, action: action)
        } else {
            action()
        }
    }

    func openOnramp(input: SendInput, parameters: PredefinedOnrampParameters) {
        let dismissAction: Action<SendCoordinator.DismissOptions?> = { [weak self] _ in
            self?.sendCoordinator = nil
        }

        let coordinator = SendCoordinator(dismissAction: dismissAction)
        let options = SendCoordinator.Options(input: input, type: .onramp(parameters: parameters), source: .markets)
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }
}

// MARK: - AccountsAwareAddTokenFlowRoutable

extension MarketsTokenDetailsCoordinator: AccountsAwareAddTokenFlowRoutable {
    func close() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
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
                await walletModel.update(silent: true, features: .balances)
            }
        }
    }

    func openViaYieldNotice(tokenItem: TokenItem, action: @escaping () -> Void) {
        let viewModel = YieldNoticeViewModel(tokenItem: tokenItem, action: action)
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
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

        coordinator.start(with: .init(info: token, style: presentationStyle, isDeeplinkMode: isDeeplinkMode))
        newsRelatedTokenDetailsCoordinator = coordinator
    }
}
