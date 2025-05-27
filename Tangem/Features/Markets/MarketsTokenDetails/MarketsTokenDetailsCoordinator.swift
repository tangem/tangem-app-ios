//
//  MarketsTokenDetailsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemUIUtils.AlertBinder

class MarketsTokenDetailsCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.tangemStoriesPresenter) private var tangemStoriesPresenter: any TangemStoriesPresenter

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
    @Published var mailViewModel: MailViewModel? = nil

    private var safariHandle: SafariHandle?

    private let portfolioCoordinatorFactory = MarketsTokenDetailsPortfolioCoordinatorFactory()

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

    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        let recipient = EmailConfig.default.recipient
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: emailType)
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
}

// MARK: - MarketsPortfolioContainerRoutable

extension MarketsTokenDetailsCoordinator {
    func openReceive(walletModel: any WalletModel) {
        receiveBottomSheetViewModel = ReceiveBottomSheetUtils(flow: .crypto).makeViewModel(for: walletModel)
    }

    func openBuyCryptoIfPossible(for walletModel: any WalletModel, with userWalletModel: UserWalletModel) {
        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(for: .exchange) {
            error = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        guard let url = portfolioCoordinatorFactory.makeBuyURL(for: walletModel, with: userWalletModel) else {
            return
        }

        openBuyCrypto(at: url, with: walletModel)
    }

    func openExchange(for walletModel: any WalletModel, with userWalletModel: UserWalletModel) {
        let dismissAction: Action<(walletModel: any WalletModel, userWalletModel: UserWalletModel)?> = { [weak self] navigationInfo in
            self?.expressCoordinator = nil
        }

        let openSwapBlock = { [weak self] in
            guard let self else { return }
            expressCoordinator = portfolioCoordinatorFactory.makeExpressCoordinator(
                for: walletModel,
                with: userWalletModel,
                dismissAction: dismissAction,
                popToRootAction: popToRootAction
            )
        }

        Task { @MainActor [tangemStoriesPresenter] in
            tangemStoriesPresenter.present(
                story: .swap(.initialWithoutImages),
                analyticsSource: .markets,
                presentCompletion: openSwapBlock
            )
        }
    }

    func openOnramp(for walletModel: any WalletModel, with userWalletModel: UserWalletModel) {
        let dismissAction: Action<SendCoordinator.DismissOptions?> = { [weak self] _ in
            self?.sendCoordinator = nil
        }

        let coordinator = SendCoordinator(dismissAction: dismissAction)
        let options = SendCoordinator.Options(
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            type: .onramp,
            source: .markets
        )
        coordinator.start(with: options)
        sendCoordinator = coordinator
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
}
