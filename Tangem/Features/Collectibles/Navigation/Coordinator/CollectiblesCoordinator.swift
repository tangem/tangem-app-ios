//
//  CollectiblesCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemStories

final class CollectiblesCoordinator: CoordinatorObject {
    // MARK: - Properties

    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter
    @Injected(\.overlayViewPresenter) var overlayViewPresenter: any OverlayViewPresenter
    @Injected(\.storiesAnalyticsProvider) var storiesAnalyticsProvider: any StoriesAnalyticsProvider

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    private var accountModel: (any CollectiblesAccountModel)?

    // MARK: - Publishers

    @Published private(set) var state: ViewState?
    @Published var machineViewModel: CollectiblesMachineViewModel?

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    // MARK: - Public methods

    func start(with options: Options) {
        accountModel = options.accountModel

        switch options.destination {
        case .welcome:
            state = .welcome(CollectiblesWelcomeViewModel(routable: self, onboarder: accountModel))
        case .main:
            Task { @MainActor [weak self] in self?.openMain() }
        }
    }

    @MainActor
    func openMain() {
        state = .main(
            CollectiblesMainViewModel(routable: self, accountModel: accountModel),
            actionsMenu: CollectiblesActionsMenuViewModel(routable: self)
        )
    }

    func closeMachine() {
        machineViewModel = nil
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

        machineViewModel = CollectiblesMachineViewModel(pack: pack)
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
