//
//  MultipleRewardsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

class MultipleRewardsCoordinator: CoordinatorObject {
    let dismissAction: Action<FeeCurrencyNavigatingDismissOption?>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: MultipleRewardsViewModel?

    // MARK: - Child coordinators

    @Published var sendCoordinator: SendCoordinator?

    // MARK: - Private

    private var options: Options?

    required init(
        dismissAction: @escaping Action<FeeCurrencyNavigatingDismissOption?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        self.options = options

        rootViewModel = .init(
            tokenItem: options.sendInput.walletModel.tokenItem,
            stakingManager: options.manager,
            coordinator: self
        )
    }
}

// MARK: - Options

extension MultipleRewardsCoordinator {
    typealias Options = StakingDetailsCoordinator.Options
}

// MARK: - Dismissal

extension MultipleRewardsCoordinator {
    func dismiss() {
        dismiss(with: nil)
    }
}

// MARK: - MultipleRewardsRoutable

extension MultipleRewardsCoordinator: MultipleRewardsRoutable {
    func openStakingSingleActionFlow(action: UnstakingModel.Action) {
        guard let options else { return }

        let sourceTokenFactory = CommonSendTransferableTokenFactory(
            userWalletInfo: options.sendInput.userWalletInfo,
            walletModel: options.sendInput.walletModel
        )
        let sourceToken = sourceTokenFactory.makeTransferableToken()

        let coordinator = SendCoordinator(dismissAction: { [weak self] option in
            self?.sendCoordinator = nil

            if case .openFeeCurrency(let feeCurrency) = option {
                self?.dismiss(with: feeCurrency)
            } else {
                self?.dismiss(with: nil)
            }
        })

        coordinator.start(with: .init(
            type: .stakingSingleAction(sourceToken, manager: options.manager, action: action),
            source: .stakingDetails
        ))
        sendCoordinator = coordinator
    }
}
