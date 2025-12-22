//
//  MarketsTokenDetailsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
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

    // MARK: - Root ViewModels

    @Published var rootViewModel: MarketsTokenDetailsViewModel? = nil
    @Published var error: AlertBinder? = nil

    // MARK: - Child ViewModels

    @Published var receiveBottomSheetViewModel: ReceiveBottomSheetViewModel? = nil
    @Published var exchangesListViewModel: MarketsTokenDetailsExchangesListViewModel? = nil

    // MARK: - Child Coordinators

    @Published var tokenNetworkSelectorCoordinator: MarketsTokenNetworkSelectorCoordinator? = nil
    @Published var sendCoordinator: SendCoordinator? = nil
    @Published var expressCoordinator: ExpressCoordinator? = nil
    @Published var stakingDetailsCoordinator: StakingDetailsCoordinator? = nil

    private var safariHandle: SafariHandle?

    private let portfolioCoordinatorFactory = MarketsTokenDetailsPortfolioCoordinatorFactory()
    private let yieldModuleNoticeInteractor = YieldModuleNoticeInteractor()

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
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
        let viewModel = MarketsTokenAccountNetworkSelectorFlowViewModel(
            inputData: .init(coinId: model.id, coinName: model.name, coinSymbol: model.symbol, networks: model.availableNetworks),
            userWalletDataProvider: walletDataProvider,
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
}

// MARK: - MarketsPortfolioContainerRoutable

extension MarketsTokenDetailsCoordinator {
    func openReceive(walletModel: any WalletModel) {
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

    func openExchange(input: ExpressDependenciesInput) {
        let action = { [weak self] in
            guard let self else { return }

            let dismissAction: ExpressCoordinator.DismissAction = { [weak self] _ in
                self?.expressCoordinator = nil
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

// MARK: - MarketsTokenAccountNetworkSelectorRoutable

extension MarketsTokenDetailsCoordinator: MarketsTokenAccountNetworkSelectorRoutable {
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

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                walletModel.update(silent: true)
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
