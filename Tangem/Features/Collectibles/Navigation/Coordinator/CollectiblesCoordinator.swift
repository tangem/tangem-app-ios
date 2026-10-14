//
//  CollectiblesCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import BlockchainSdk
import TangemFoundation
import TangemStories
import TangemCollectibles

final class CollectiblesCoordinator: CoordinatorObject {
    // MARK: - Properties

    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter
    @Injected(\.storiesAnalyticsProvider) var storiesAnalyticsProvider: any StoriesAnalyticsProvider
    @Injected(\.overlayViewPresenter) var overlayViewPresenter: any OverlayViewPresenter

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    private var accountModel: (any CollectiblesAccountModel)?
    private var userWalletID = ""

    // [REDACTED_TODO_COMMENT]
    private var devnetUserWalletModel: (any UserWalletModel)?

    private(set) var fundsCoordinator: FundsCoordinator?

    // MARK: - Publishers

    @Published private(set) var state: ViewState?
    @Published var machineViewModel: CollectiblesMachineViewModel?
    @Published var confirmOrderViewModel: CollectiblesConfirmOrderViewModel?

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    // MARK: - Public methods

    func start(with options: Options) {
        accountModel = options.accountModel
        userWalletID = options.userWalletModel.userWalletId.stringValue
        devnetUserWalletModel = options.userWalletModel

        startFundsCoordinator(with: options)
        open(options.destination)
    }

    @MainActor
    func openMain() {
        state = .main(
            CollectiblesMainViewModel(routable: self, accountModel: accountModel),
            // [REDACTED_TODO_COMMENT]
            actionsMenu: CollectiblesActionsMenuViewModel(routable: self, devnet: makeDevnetMenuViewModel())
        )
    }

    func closeConfirmOrder() {
        confirmOrderViewModel = nil
    }
}

// MARK: - Routables

extension CollectiblesCoordinator: CollectiblesWelcomeRoutable {
    func openLegalTerms(url: URL) {
        safariManager.openURL(url)
    }
}

extension CollectiblesCoordinator: CollectiblesMainRoutable {
    func openMachine(for pack: CollectiblesPack) {
        guard machineViewModel == nil else { return }

        confirmOrderViewModel = nil
        machineViewModel = CollectiblesMachineViewModel(
            pack: pack,
            routable: self,
            prizePoolProvider: CommonCollectiblesPrizePoolProvider(userWalletID: userWalletID)
        )
    }

    func openSupport() {
        let logsComposer = LogsComposer(infoProvider: BaseDataCollector())
        let mailViewModel = MailViewModel(
            logsComposer: logsComposer,
            recipient: EmailConfig.default.recipient,
            emailType: .appFeedback(subject: EmailConfig.default.subject)
        )

        Task { @MainActor in
            mailPresenter.present(viewModel: mailViewModel)
        }
    }
}

extension CollectiblesCoordinator: CollectiblesMachineRoutable {
    // [REDACTED_TODO_COMMENT]
    func openConfirmOrder(machineID: String, machine: CollectiblesMachine, isTurboModeOn _: Bool) {
        guard confirmOrderViewModel == nil, let accountModel else { return }

        confirmOrderViewModel = CollectiblesConfirmOrderViewModel(
            machineID: machineID,
            machine: machine,
            usdcBalanceProvider: accountModel.usdcTokenBalanceProvider,
            purchaseInteractor: accountModel.purchaseInteractor,
            routable: self,
            refreshBalance: accountModel.refreshState
        )
    }
}

// MARK: - CollectiblesConfirmOrderRoutable

extension CollectiblesCoordinator: CollectiblesConfirmOrderRoutable {
    func closePackFlow() {
        machineViewModel = nil
    }
}

// MARK: - Private logic

private extension CollectiblesCoordinator {
    func startFundsCoordinator(with options: Options) {
        guard let accountModel = options.accountModel else {
            return
        }

        let coordinator = FundsCoordinator(dismissAction: {}, popToRootAction: popToRootAction)
        coordinator.start(with: .init(
            accountModel: accountModel,
            userWalletInfo: options.userWalletModel.userWalletInfo,
            walletModelsProvider: MainScreenUIOrderedWalletModelsProvider(userWalletModel: options.userWalletModel)
        ))
        fundsCoordinator = coordinator
    }

    func open(_ destination: Options.Destination) {
        switch destination {
        case .welcome:
            state = .welcome(CollectiblesWelcomeViewModel(routable: self, onboarder: accountModel))
        case .main:
            Task { @MainActor [weak self] in self?.openMain() }
        }
    }
}

// MARK: - Devnet menu

// [REDACTED_TODO_COMMENT]
private extension CollectiblesCoordinator {
    @MainActor
    func makeDevnetMenuViewModel() -> CollectiblesDevnetMenuViewModel? {
        guard !AppEnvironment.current.isProduction,
              CollectiblesChainEnvironment.blockchain.isTestnet,
              let accountModel,
              let userWalletModel = devnetUserWalletModel else {
            return nil
        }

        let actions = CommonCollectiblesDevnetActions(accountModel: accountModel, userWalletModel: userWalletModel)

        return CollectiblesDevnetMenuViewModel(actions: actions) { [weak self] in
            self?.dismiss()
        }
    }
}

// MARK: - Nested types

extension CollectiblesCoordinator {
    struct Options {
        let destination: Destination
        let userWalletModel: any UserWalletModel
        let accountModel: (any CollectiblesAccountModel)?

        init(
            destination: Destination,
            userWalletModel: any UserWalletModel,
            accountModel: (any CollectiblesAccountModel)?
        ) {
            self.destination = destination
            self.userWalletModel = userWalletModel
            self.accountModel = accountModel
        }

        enum Destination {
            case welcome
            case main
        }
    }

    enum ViewState {
        case welcome(CollectiblesWelcomeViewModel)
        case main(CollectiblesMainViewModel, actionsMenu: CollectiblesActionsMenuViewModel)
    }
}
