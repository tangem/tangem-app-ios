//
//  MainCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MainCoordinator: CoordinatorObject {
    let dismissAction: Action
    let popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var mainViewModel: MainViewModel?

    // MARK: - Child coordinators

    @Published var detailsCoordinator: DetailsCoordinator?
    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator?
    @Published var modalOnboardingCoordinator: OnboardingCoordinator?

    // MARK: - Child view models

    @Published var mailViewModel: MailViewModel?

    // MARK: - Other state

    @Published var modalOnboardingCoordinatorKeeper: Bool = false
    @Published var organizeTokensViewModel: OrganizeTokensViewModel? = nil

    required init(
        dismissAction: @escaping Action,
        popToRootAction: @escaping ParamsAction<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        mainViewModel = MainViewModel(
            selectedUserWalletId: options.userWalletModel.userWalletId,
            coordinator: self,
            mainUserWalletPageBuilderFactory: CommonMainUserWalletPageBuilderFactory(coordinator: self)
        )
    }
}

// MARK: - Options

extension MainCoordinator {
    struct Options {
        let userWalletModel: UserWalletModel
    }
}

// MARK: - MainRoutable protocol conformance

extension MainCoordinator: MainRoutable {
    func openDetails(for cardModel: CardViewModel) {
        let dismissAction: Action = { [weak self] in
            self?.detailsCoordinator = nil
        }

        let coordinator = DetailsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        let options = DetailsCoordinator.Options(cardModel: cardModel)
        coordinator.start(with: options)
        coordinator.popToRootAction = popToRootAction
        detailsCoordinator = coordinator
    }

    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: emailType)
    }

    func openOnboardingModal(with input: OnboardingInput) {
        let dismissAction: Action = { [weak self] in
            self?.modalOnboardingCoordinator = nil
            self?.mainViewModel?.updateIsBackupAllowed()
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        let options = OnboardingCoordinator.Options(input: input, destination: .dismiss)
        coordinator.start(with: options)
        modalOnboardingCoordinator = coordinator
    }

    func close(newScan: Bool) {
        popToRoot(with: .init(newScan: newScan))
    }
}

// MARK: - MultiWalletMainContentRoutable protocol conformance

extension MainCoordinator: MultiWalletMainContentRoutable {
    func openTokenDetails(for model: WalletModel, userWalletModel: UserWalletModel) {
        // [REDACTED_TODO_COMMENT]
        guard let cardViewModel = userWalletModel as? CardViewModel else {
            return
        }

        Analytics.log(.tokenIsTapped)
        let dismissAction: Action = { [weak self] in
            self?.tokenDetailsCoordinator = nil
        }
        let coordinator = TokenDetailsCoordinator(dismissAction: dismissAction)
        coordinator.start(
            with: .init(
                cardModel: cardViewModel,
                walletModel: model,
                userTokensManager: userWalletModel.userTokensManager,
                blockchainNetwork: model.blockchainNetwork,
                amountType: model.amountType
            )
        )

        tokenDetailsCoordinator = coordinator
    }

    func openOrganizeTokens(for userWalletModel: UserWalletModel) {
        let userTokenListManager = userWalletModel.userTokenListManager
        let optionsManager = OrganizeTokensOptionsManager(
            userTokenListManager: userTokenListManager,
            editingThrottleInterval: 1.0
        )
        let walletModelComponentsBuilder = WalletModelComponentsBuilder(
            supportedBlockchains: userWalletModel.config.supportedBlockchains
        )
        let walletModelsAdapter = OrganizeWalletModelsAdapter(
            userTokenListManager: userTokenListManager,
            walletModelComponentsBuilder: walletModelComponentsBuilder,
            organizeTokensOptionsProviding: optionsManager,
            organizeTokensOptionsEditing: optionsManager
        )

        organizeTokensViewModel = OrganizeTokensViewModel(
            coordinator: self,
            walletModelsManager: userWalletModel.walletModelsManager,
            walletModelsAdapter: walletModelsAdapter,
            organizeTokensOptionsProviding: optionsManager,
            organizeTokensOptionsEditing: optionsManager
        )
    }
}

// MARK: - SingleWalletMainContentRoutable protocol conformance

extension MainCoordinator: SingleWalletMainContentRoutable {}

// MARK: - OrganizeTokensRoutable protocol conformance

extension MainCoordinator: OrganizeTokensRoutable {
    func didTapCancelButton() {
        organizeTokensViewModel = nil
    }
}
