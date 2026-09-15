//
//  CollectiblesCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

final class CollectiblesCoordinator: CoordinatorObject {
    // MARK: - Properties

    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter
    @Injected(\.overlayViewPresenter) var overlayViewPresenter: any OverlayViewPresenter

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

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
        switch options.destination {
        case .welcome:
            state = .welcome(CollectiblesWelcomeViewModel(routable: self, onboarder: makeOnboarder(options: options)))
        case .main:
            Task { @MainActor [weak self] in self?.openMain() }
        }
    }

    @MainActor
    func openMain() {
        state = .main(
            CollectiblesMainViewModel(routable: self),
            actionsMenu: CollectiblesActionsMenuViewModel(routable: self)
        )
    }

    func closeMachine() {
        machineViewModel = nil
    }

    private func makeOnboarder(options: Options) -> any CollectiblesOnboarder {
        CommonCollectiblesOnboarder(userWalletModel: options.userWalletModel)
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

        init(destination: Destination, userWalletModel: any UserWalletModel) {
            self.destination = destination
            self.userWalletModel = userWalletModel
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
