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

class MarketsPortfolioContainerViewModel: ObservableObject {
    // MARK: - Services

    @Injected(\.swapAvailabilityProvider) private var swapAvailabilityProvider: SwapAvailabilityProvider

    // MARK: - Published Properties

    @Published var isShowTopAddButton: Bool = false
    @Published var typeView: MarketsPortfolioContainerView.TypeView?
    @Published var tokenItemViewModels: [MarketsPortfolioTokenItemViewModel] = []
    @Published var quickActions: [TokenActionType] = []

    // MARK: - Private Properties

    private var userWalletModels: [UserWalletModel] {
        walletDataProvider.userWalletModels
    }

    private let walletDataProvider: MarketsWalletDataProvider
    private let tokenActionContextBuilder = TokenActionContextBuilder()

    private weak var coordinator: MarketsPortfolioContainerRoutable?
    private var addTokenTapAction: (() -> Void)?

    private var inputData: InputData
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        inputData: InputData,
        walletDataProvider: MarketsWalletDataProvider,
        coordinator: MarketsPortfolioContainerRoutable?,
        addTokenTapAction: (() -> Void)?
    ) {
        self.inputData = inputData
        self.walletDataProvider = walletDataProvider
        self.coordinator = coordinator
        self.addTokenTapAction = addTokenTapAction

        bind()
    }

    // MARK: - Public Implementation

    func onAddTapAction() {
        addTokenTapAction?()
    }

    // MARK: - Private Implementation

    private func updateUI() {
        updateTokenList()

        let canAddAvailableNetworks = canAddToPortfolio(with: inputData.networks)

        guard canAddAvailableNetworks else {
            typeView = tokenItemViewModels.isEmpty ? .unavailable : .list
            return
        }

        isShowTopAddButton = !tokenItemViewModels.isEmpty
        typeView = tokenItemViewModels.isEmpty ? .empty : .list
    }

    /*
     - We are joined the list of available blockchains so far, all user wallet models
     - We get a list of available blockchains that came in the coin model
     - Checking the lists of available networks
     */
    private func canAddToPortfolio(with networks: [NetworkModel]) -> Bool {
        let multiCurrencyUserWalletModels = userWalletModels.filter { $0.config.hasFeature(.multiCurrency) }

        guard
            !networks.isEmpty,
            !multiCurrencyUserWalletModels.isEmpty
        else {
            return false
        }

        var networkIds = Set<String>()

        networks.forEach {
            networkIds.insert($0.networkId)
        }

        for model in multiCurrencyUserWalletModels {
            if !networkIds.intersection(model.config.supportedBlockchains.map { $0.networkId }).isEmpty {
                return true
            }
        }

        return false
    }

    private func updateTokenList() {
        let portfolioTokenItemFactory = MarketsPortfolioTokenItemFactory(
            contextActionsProvider: self,
            contextActionsDelegate: self
        )

        let tokenItemViewModelByUserWalletModels: [MarketsPortfolioTokenItemViewModel] = userWalletModels
            .reduce(into: []) { partialResult, userWalletModel in
                let walletModels = userWalletModel.walletModelsManager.walletModels
                let entries = userWalletModel.userTokenListManager.userTokensList.entries

                let viewModels: [MarketsPortfolioTokenItemViewModel] = portfolioTokenItemFactory.makeViewModels(
                    coinId: inputData.coinId,
                    networks: inputData.networks,
                    walletModels: walletModels,
                    entries: entries,
                    userWalletInfo: MarketsPortfolioTokenItemFactory.UserWalletInfo(
                        userWalletName: userWalletModel.name,
                        userWalletId: userWalletModel.userWalletId
                    )
                )

                partialResult.append(contentsOf: viewModels)
            }

        quickActions = makeQuickActions()
        tokenItemViewModels = tokenItemViewModelByUserWalletModels
    }

    private func bind() {
        let publishers = userWalletModels.map { $0.userTokenListManager.userTokensListPublisher }

        Publishers.MergeMany(publishers)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.updateUI()
            }
            .store(in: &bag)
    }

    private func makeQuickActions() -> [TokenActionType] {
        let targetActions = tokenItemViewModels.count == 1 ? [TokenActionType.receive, TokenActionType.exchange, TokenActionType.buy] : []
        let filteredActions = tokenItemViewModels.first?.contextActions.filter { targetActions.contains($0) }
        return filteredActions ?? []
    }
}

extension MarketsPortfolioContainerViewModel: MarketsPortfolioContextActionsProvider {
    func buildContextActions(walletModelId: WalletModelId, userWalletId: UserWalletId) -> [TokenActionType] {
        guard let userWalletModel = userWalletModels.first(where: { $0.userWalletId == userWalletId }) else {
            return []
        }

        let actions = tokenActionContextBuilder.buildContextActions(for: walletModelId, with: userWalletModel)
        return actions
    }
}

// MARK: - MarketsPortfolioContextActionsDelegate

extension MarketsPortfolioContainerViewModel: MarketsPortfolioContextActionsDelegate {
    func didTapContextAction(_ action: TokenActionType, walletModelId: WalletModelId, userWalletId: UserWalletId) {
        let userWalletModel = userWalletModels.first(where: { $0.userWalletId == userWalletId })
        let walletModel = userWalletModel?.walletModelsManager.walletModels.first(where: { $0.id == walletModelId.id })

        guard let userWalletModel, let walletModel, let coordinator else {
            return
        }

        Analytics.log(event: .marketsActionButtons, params: [.button: action.analyticsParameterValue])

        switch action {
        case .buy:
            coordinator.openBuyCryptoIfPossible(for: walletModel, with: userWalletModel)
        case .send:
            coordinator.openSend(for: walletModel, with: userWalletModel)
        case .receive:
            coordinator.openReceive(walletModel: walletModel)
        case .sell:
            coordinator.openSell(for: walletModel, with: userWalletModel)
        case .copyAddress:
            UIPasteboard.general.string = walletModel.defaultAddress

            Toast(view: SuccessToast(text: Localization.walletNotificationAddressCopied))
                .present(layout: .bottom(padding: 80), type: .temporary())
        case .exchange:
            coordinator.openExchange(for: walletModel, with: userWalletModel)
        case .stake:
            coordinator.openStaking(for: walletModel, with: userWalletModel)
        case .hide:
            return
        }
    }
}

extension MarketsPortfolioContainerViewModel {
    struct InputData {
        let coinId: String
        let networks: [NetworkModel]
    }
}
