//
//  StakingDetailsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking
import BlockchainSdk

class StakingDetailsCoordinator: CoordinatorObject, FeeCurrencyNavigating {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Root view model

    @Published private(set) var rootViewModel: StakingDetailsViewModel?

    // MARK: - Child coordinators

    @Published var sendCoordinator: SendCoordinator?
    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator?
    @Published var multipleRewardsCoordinator: MultipleRewardsCoordinator?

    // MARK: - Private

    private var options: Options?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        self.options = options

        rootViewModel = StakingDetailsViewModel(
            tokenItem: options.walletModel.tokenItem,
            tokenBalanceProvider: options.walletModel.availableBalanceProvider,
            stakingManager: options.manager,
            coordinator: self
        )
    }
}

// MARK: - Options

extension StakingDetailsCoordinator {
    struct Options {
        let userWalletModel: UserWalletModel
        let walletModel: any WalletModel
        let manager: StakingManager
    }
}

// MARK: - StakingDetailsRoutable

extension StakingDetailsCoordinator: StakingDetailsRoutable {
    func openStakingFlow() {
        guard let options else { return }

        openFlow(
            options: options,
            sendType: .staking(
                manager: options.manager,
                blockchainParams: .init(blockchain: options.walletModel.tokenItem.blockchain)
            )
        )

        Analytics.log(
            event: .stakingButtonStake,
            params: [
                .source: Analytics.ParameterValue.stakeSourceStakeInfo.rawValue,
                .token: options.walletModel.tokenItem.currencySymbol,
            ]
        )
    }

    func openMultipleRewards() {
        guard let options else { return }

        let coordinator = MultipleRewardsCoordinator(dismissAction: { [weak self] _ in
            self?.multipleRewardsCoordinator = nil
        })

        coordinator.start(with: options)

        multipleRewardsCoordinator = coordinator
    }

    func openUnstakingFlow(action: UnstakingModel.Action) {
        guard let options else { return }

        openFlow(options: options, sendType: .unstaking(manager: options.manager, action: action))
    }

    func openRestakingFlow(action: RestakingModel.Action) {
        guard let options else { return }

        openFlow(options: options, sendType: .restaking(manager: options.manager, action: action))
    }

    func openStakingSingleActionFlow(action: StakingSingleActionModel.Action) {
        guard let options else { return }

        openFlow(options: options, sendType: .stakingSingleAction(manager: options.manager, action: action))
    }

    func openFlow(options: Options, sendType: SendType) {
        let coordinator = makeSendCoordinator()

        coordinator.start(
            with: .init(
                input: .init(
                    userWalletInfo: options.userWalletModel.userWalletInfo,
                    walletModel: options.walletModel,
                    expressInput: .init(userWalletModel: options.userWalletModel)
                ),
                type: sendType,
                source: .stakingDetails
            )
        )
        sendCoordinator = coordinator
    }

    func openWhatIsStaking() {
        let tokenSymbol = options?.walletModel.tokenItem.currencySymbol ?? ""
        Analytics.log(event: .stakingLinkWhatIsStaking, params: [.token: tokenSymbol])
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .whatIsStaking))
    }
}
