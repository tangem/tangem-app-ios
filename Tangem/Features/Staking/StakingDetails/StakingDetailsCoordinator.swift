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

class StakingDetailsCoordinator: CoordinatorObject, SendFeeCurrencyNavigating {
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
            tokenItem: options.sendInput.walletModel.tokenItem,
            tokenBalanceProvider: options.sendInput.walletModel.availableBalanceProvider,
            stakingManager: options.manager,
            coordinator: self,
            deeplinkHandler: PromotionDeeplinkHandler(
                coordinator: self,
                walletModel: options.sendInput.walletModel,
                userWalletInfo: options.sendInput.userWalletInfo
            )
        )
    }
}

// MARK: - Options

extension StakingDetailsCoordinator {
    struct Options {
        let sendInput: SendInput
        let manager: StakingManager
    }
}

// MARK: - StakingDetailsRoutable

extension StakingDetailsCoordinator: StakingDetailsRoutable {
    func openStakingFlow() {
        guard let options else { return }

        let factory = CommonSendTransferableTokenFactory(
            userWalletInfo: options.sendInput.userWalletInfo,
            walletModel: options.sendInput.walletModel
        )
        let sourceToken = factory.makeTransferableToken()

        openFlow(
            options: options,
            sendType: .staking(
                sourceToken,
                manager: options.manager,
                walletModelDependenciesProvider: options.sendInput.walletModel,
                blockchainParams: .init(blockchain: options.sendInput.walletModel.tokenItem.blockchain)
            )
        )

        Analytics.log(
            event: .stakingButtonStake,
            params: [
                .source: Analytics.ParameterValue.stakeSourceStakeInfo.rawValue,
                .token: options.sendInput.walletModel.tokenItem.currencySymbol,
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

        let factory = CommonSendTransferableTokenFactory(
            userWalletInfo: options.sendInput.userWalletInfo,
            walletModel: options.sendInput.walletModel
        )
        let sourceToken = factory.makeTransferableToken(balanceType: .staked(action: action))

        openFlow(options: options, sendType: .unstaking(sourceToken, manager: options.manager, action: action))
    }

    func openRestakingFlow(action: RestakingModel.Action) {
        guard let options else { return }

        let factory = CommonSendTransferableTokenFactory(
            userWalletInfo: options.sendInput.userWalletInfo,
            walletModel: options.sendInput.walletModel
        )
        let sourceToken = factory.makeTransferableToken()

        openFlow(options: options, sendType: .restaking(sourceToken, manager: options.manager, action: action))
    }

    func openStakingSingleActionFlow(action: StakingSingleActionModel.Action) {
        guard let options else { return }

        let factory = CommonSendTransferableTokenFactory(
            userWalletInfo: options.sendInput.userWalletInfo,
            walletModel: options.sendInput.walletModel
        )
        let sourceToken = factory.makeTransferableToken()

        openFlow(options: options, sendType: .stakingSingleAction(sourceToken, manager: options.manager, action: action))
    }

    func openFlow(options: Options, sendType: SendType) {
        let coordinator = makeSendCoordinator()

        coordinator.start(
            with: .init(
                type: sendType,
                source: .stakingDetails
            )
        )
        sendCoordinator = coordinator
    }

    func openWhatIsStaking() {
        let tokenSymbol = options?.sendInput.walletModel.tokenItem.currencySymbol ?? ""
        Analytics.log(event: .stakingLinkWhatIsStaking, params: [.token: tokenSymbol])
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .whatIsStaking))
    }
}

// MARK: - PromotionDeeplinkRoutable

extension StakingDetailsCoordinator: PromotionDeeplinkRoutable {
    func openSwap(parameters: PredefinedSwapParameters) {
        let coordinator = makeSendCoordinator()
        coordinator.start(with: .init(type: .swap(parameters), source: .stakingDetails))
        sendCoordinator = coordinator
    }

    func openOnramp(input: SendInput, parameters: PredefinedOnrampParameters) {
        let sourceToken = CommonSendTransferableTokenFactory(
            userWalletInfo: input.userWalletInfo,
            walletModel: input.walletModel
        ).makeTransferableToken()

        let coordinator = makeSendCoordinator()
        coordinator.start(with: .init(type: .onramp(sourceToken, parameters: parameters), source: .stakingDetails))
        sendCoordinator = coordinator
    }

    func openInSafari(url: URL) {
        safariManager.openURL(url)
    }
}
