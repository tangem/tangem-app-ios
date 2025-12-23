//
//  MarketsPortfolioContainerViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import BlockchainSdk
import TangemFoundation

/// Legacy VM w/o accounts supports, use `MarketsAccountsAwarePortfolioContainerViewModel` instead when accounts are available.
final class MarketsPortfolioContainerViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isAddTokenButtonDisabled: Bool = true
    @Published var isLoadingNetworks: Bool = false
    @Published var typeView: MarketsPortfolioContainerView.TypeView = .loading
    @Published var tokenItemViewModels: [MarketsPortfolioTokenItemViewModel] = []
    @Published var tokenWithExpandedQuickActions: MarketsPortfolioTokenItemViewModel?

    // MARK: - Private Properties

    private let walletDataProvider: MarketsWalletDataProvider
    private weak var coordinator: MarketsPortfolioContainerRoutable?
    private var addTokenTapAction: (() -> Void)?

    private var coinId: String
    private var networks: [NetworkModel]?

    private var userWalletModelsListSubscription: AnyCancellable?
    private var tokensListsUpdateSubscription: AnyCancellable?

    // MARK: - Init

    init(
        inputData: InputData,
        walletDataProvider: MarketsWalletDataProvider,
        coordinator: MarketsPortfolioContainerRoutable?,
        addTokenTapAction: (() -> Void)?
    ) {
        coinId = inputData.coinId
        self.walletDataProvider = walletDataProvider
        self.coordinator = coordinator
        self.addTokenTapAction = addTokenTapAction

        updateUI(availableNetworks: nil, animated: false)
        bind()
    }

    // MARK: - Public Implementation

    func onAddTapAction() {
        addTokenTapAction?()
    }

    func update(networks: [NetworkModel]) {
        updateUI(availableNetworks: networks, animated: true)
    }

    // MARK: - Private Implementation

    private func updateUI(availableNetworks: [NetworkModel]?, animated: Bool) {
        networks = availableNetworks
        updateTokenList()
        updateExpandedAction()

        var targetState: MarketsPortfolioContainerView.TypeView = .list
        if let networks {
            let supportedStateNetworks = supportedState(networks: networks)
            isAddTokenButtonDisabled = tokenAddedToAllNetworksAndWallets(availableNetworks: networks)

            if tokenItemViewModels.isEmpty {
                switch supportedStateNetworks {
                case .available:
                    targetState = .empty
                case .unavailable:
                    targetState = .unavailable
                case .unsupported:
                    targetState = .unsupported
                }
            }
        } else if tokenItemViewModels.isEmpty {
            targetState = .loading
        }

        withAnimation(animated ? .default : nil) {
            typeView = targetState
            isLoadingNetworks = availableNetworks == nil
        }
    }

    /**
     - We are joined the list of available blockchains so far, all user wallet models
     - We get a list of available blockchains that came in the coin model
     - Checking the lists of available networks
     */
    private func supportedState(networks: [NetworkModel]) -> SupportedStateOption {
        let multiCurrencyUserWalletModels = walletDataProvider.userWalletModels.filter { $0.config.hasFeature(.multiCurrency) }

        guard !networks.isEmpty else {
            return .unsupported
        }

        for model in multiCurrencyUserWalletModels {
            let supportedBlockchains = model.config.supportedBlockchains

            for network in networks {
                if let supportedBlockchain = supportedBlockchains[network.networkId] {
                    if network.contractAddress == nil {
                        return .available
                    }

                    // searchable network is token
                    if supportedBlockchain.canHandleTokens {
                        return .available
                    }
                }
            }
        }

        return .unavailable
    }

    private func tokenAddedToAllNetworksAndWallets(availableNetworks: [NetworkModel]) -> Bool {
        if availableNetworks.isEmpty {
            return true
        }

        let l2BlockchainsIds = SupportedBlockchains.l2Blockchains.map { $0.coinId }

        for userWalletModel in walletDataProvider.userWalletModels {
            guard userWalletModel.config.hasFeature(.multiCurrency) else {
                continue
            }

            let supportedBlockchains = userWalletModel.config.supportedBlockchains

            let supportedNetworkIds = availableNetworks
                .filter { NetworkSupportChecker.isNetworkSupported($0, in: supportedBlockchains) }
                .map(\.networkId)
                .toSet()

            var networkIds = supportedNetworkIds
            // accounts_fixes_needed_none
            let userTokenList = userWalletModel.userTokensManager.userTokens
            for entry in userTokenList {
                guard let entryId = entry.id else {
                    continue
                }

                // L2 networks
                if coinId == Blockchain.ethereum(testnet: false).coinId,
                   l2BlockchainsIds.contains(entryId) {
                    networkIds.remove(entry.blockchainNetwork.blockchain.networkId)
                    continue
                }

                guard entryId == coinId else {
                    continue
                }

                networkIds.remove(entry.blockchainNetwork.blockchain.networkId)
            }

            if !networkIds.isEmpty {
                return false
            }
        }

        return true
    }

    private func updateTokenList() {
        let portfolioTokenItemFactory = MarketsPortfolioTokenItemFactory(
            contextActionsProvider: self,
            contextActionsDelegate: self
        )

        let tokenItemViewModelByUserWalletModels: [MarketsPortfolioTokenItemViewModel] = walletDataProvider.userWalletModels
            .reduce(into: []) { partialResult, userWalletModel in
                // accounts_fixes_needed_none
                let walletModels = userWalletModel.walletModelsManager.walletModels
                // accounts_fixes_needed_none
                let entries = userWalletModel.userTokensManager.userTokens

                let viewModels: [MarketsPortfolioTokenItemViewModel] = portfolioTokenItemFactory.makeViewModels(
                    coinId: coinId,
                    walletModels: walletModels,
                    entries: entries,
                    userWalletInfo: MarketsPortfolioTokenItemFactory.UserWalletInfo(
                        userWalletName: userWalletModel.name,
                        userWalletId: userWalletModel.userWalletId
                    )
                )

                partialResult.append(contentsOf: viewModels)
            }

        tokenItemViewModels = tokenItemViewModelByUserWalletModels
        updateExpandedAction()
    }

    private func updateExpandedAction() {
        guard
            tokenItemViewModels.count == 1,
            let tokenViewModel = tokenItemViewModels.first,
            tokenViewModel.hasZeroBalance
        else {
            tokenWithExpandedQuickActions = nil
            return
        }

        tokenWithExpandedQuickActions = tokenViewModel
    }

    private func bind() {
        userWalletModelsListSubscription = walletDataProvider.userWalletModelsPublisher
            .sink(receiveValue:
                weakify(self, forFunction: MarketsPortfolioContainerViewModel.bindToTokensListsUpdates(userWalletModels:))
            )
    }

    private func bindToTokensListsUpdates(userWalletModels: [UserWalletModel]) {
        // accounts_fixes_needed_none
        let publishers = userWalletModels.map { $0.userTokensManager.userTokensPublisher }
        let walletModelsPublishers = userWalletModels.map { $0.walletModelsManager.walletModelsPublisher }

        let manyUserTokensListPublishers = Publishers.MergeMany(publishers)
        let manyWalletModelsPublishers = Publishers.MergeMany(walletModelsPublishers)

        tokensListsUpdateSubscription = manyUserTokensListPublishers
            .combineLatest(manyWalletModelsPublishers)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.updateUI(availableNetworks: viewModel.networks, animated: true)
            }
    }
}

extension MarketsPortfolioContainerViewModel: MarketsPortfolioContextActionsProvider {
    func buildContextActions(tokenItem: TokenItem, walletModelId: WalletModelId, userWalletId: UserWalletId) -> [TokenActionType] {
        guard let userWalletModel = walletDataProvider.userWalletModels[userWalletId],
              // accounts_fixes_needed_none
              let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: { $0.id == walletModelId }) else {
            return []
        }

        let tokenActionAvailabilityProvider = TokenActionAvailabilityProvider(userWalletConfig: userWalletModel.config, walletModel: walletModel)

        let marketsActions = tokenActionAvailabilityProvider.buildMarketsTokenContextActions()
        return marketsActions
    }
}

// MARK: - MarketsPortfolioContextActionsDelegate

extension MarketsPortfolioContainerViewModel: MarketsPortfolioContextActionsDelegate {
    func showContextAction(for viewModel: MarketsPortfolioTokenItemViewModel) {
        withAnimation {
            if tokenWithExpandedQuickActions === viewModel {
                tokenWithExpandedQuickActions = nil
            } else {
                tokenWithExpandedQuickActions = viewModel
            }
        }
    }

    func didTapContextAction(_ action: TokenActionType, walletModelId: WalletModelId, userWalletId: UserWalletId) {
        let userWalletModel = walletDataProvider.userWalletModels[userWalletId]
        // accounts_fixes_needed_none
        let walletModel = userWalletModel?.walletModelsManager.walletModels.first(where: { $0.id == walletModelId })

        guard let userWalletModel, let walletModel, let coordinator else {
            return
        }

        let sendInput = SendInput(userWalletInfo: userWalletModel.userWalletInfo, walletModel: walletModel)

        let analyticsParams: [Analytics.ParameterKey: String] = [
            .source: Analytics.ParameterValue.market.rawValue,
            .token: walletModel.tokenItem.currencySymbol.uppercased(),
            .blockchain: walletModel.tokenItem.blockchain.displayName,
        ]

        switch action {
        case .buy:
            Analytics.log(event: .marketsChartButtonBuy, params: analyticsParams)
            let parameters = PredefinedOnrampParametersBuilder.makeMoonpayPromotionParametersIfActive()
            coordinator.openOnramp(input: sendInput, parameters: parameters)
        case .receive:
            Analytics.log(event: .marketsChartButtonReceive, params: analyticsParams)
            coordinator.openReceive(walletModel: walletModel)
        case .exchange:
            Analytics.log(event: .marketsChartButtonSwap, params: analyticsParams)
            let expressInput = ExpressDependenciesInput(
                userWalletInfo: userWalletModel.userWalletInfo,
                source: ExpressInteractorWalletModelWrapper(
                    userWalletInfo: userWalletModel.userWalletInfo,
                    walletModel: walletModel,
                    expressOperationType: .swap
                ),
                destination: .loadingAndSet
            )
            coordinator.openExchange(input: expressInput)
        case .stake:
            Analytics.log(event: .marketsChartButtonStake, params: analyticsParams)
            if let stakingManager = walletModel.stakingManager {
                coordinator.openStaking(input: sendInput, stakingManager: stakingManager)
            }
        case .hide, .marketsDetails, .send, .sell, .copyAddress:
            // An empty value because it is not available
            return
        }
    }
}

extension MarketsPortfolioContainerViewModel {
    struct InputData {
        let coinId: String
    }

    enum SupportedStateOption {
        case available
        case unavailable
        case unsupported
    }
}
