//
//  MarketsAccountsAwarePortfolioContainerViewModel.swift
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
import TangemAccounts

/// Copy-pasted and adapted for accounts `MarketsPortfolioContainerViewModel`
class MarketsAccountsAwarePortfolioContainerViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isAddTokenButtonDisabled: Bool = true
    @Published var isLoadingNetworks: Bool = false
    @Published var typeView: TypeView = .loading
    @Published var tokenItemViewModels: [MarketsPortfolioTokenItemViewModel] = []
    @Published var tokenWithExpandedQuickActions: MarketsPortfolioTokenItemViewModel?

    private var bag = Set<AnyCancellable>()

    // MARK: - Private Properties

    private let walletDataProvider: MarketsWalletDataProvider
    private weak var coordinator: MarketsPortfolioContainerRoutable?
    private var addTokenTapAction: (() -> Void)?

    private var coinId: String

    // Make networks a publisher so changes trigger reactive pipeline
    private let networksSubject = CurrentValueSubject<[NetworkModel]?, Never>(nil)
    private var networks: [NetworkModel]? {
        networksSubject.value
    }

    private var userWalletModelsListSubscription: AnyCancellable?

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

        bind()
    }

    // MARK: - Public Implementation

    func onAddTapAction() {
        addTokenTapAction?()
    }

    func update(networks: [NetworkModel]) {
        networksSubject.send(networks)
    }

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

        let availableNetworksIds = availableNetworks.reduce(into: Set<String>()) { $0.insert($1.networkId) }
        let l2BlockchainsIds = SupportedBlockchains.l2Blockchains.map { $0.coinId }

        for userWalletModel in walletDataProvider.userWalletModels {
            guard userWalletModel.config.hasFeature(.multiCurrency) else {
                continue
            }

            var networkIds = availableNetworksIds
            // accounts_fixes_needed_markets
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

    private func updateExpandedAction() {
        tokenWithExpandedQuickActions = tokenItemViewModels.singleElement?.hasZeroBalance == true
            ? tokenItemViewModels.singleElement
            : nil
    }

    // MARK: - Reactive Bindings

    /// Binds to user wallet models list changes
    private func bind() {
        userWalletModelsListSubscription = walletDataProvider.userWalletModelsPublisher
            .sink(receiveValue:
                weakify(self, forFunction: MarketsAccountsAwarePortfolioContainerViewModel.bindToUserWalletUpdates(userWalletModels:))
            )
    }

    private func bindToUserWalletUpdates(userWalletModels: [UserWalletModel]) {
        bag.removeAll()

        let walletDataPublishers = userWalletModels.map { userWalletModel in
            userWalletModel.accountModelsManager.accountModelsPublisher
                .withWeakCaptureOf(self)
                .flatMap { viewModel, accountModels -> AnyPublisher<WalletData, Never> in
                    let cryptoAccounts = accountModels.compactMap { accountModel -> [any CryptoAccountModel]? in
                        guard case .standard(let cryptoAccounts) = accountModel else { return nil }
                        return viewModel.extractAccounts(from: cryptoAccounts)
                    }.flatMap { $0 }

                    let walletModelsPublishers = cryptoAccounts.map(\.walletModelsManager.walletModelsPublisher)
                    let userTokensPublishers = cryptoAccounts.map(\.userTokensManager.userTokensPublisher)

                    let combinedWalletModelsPublisher = walletModelsPublishers.combineLatest()
                    let combinedUserTokensPublishers = userTokensPublishers.combineLatest()

                    return Publishers.CombineLatest(
                        combinedWalletModelsPublisher,
                        combinedUserTokensPublishers
                    )
                    .map { walletModelsArrays, userTokensArrays in
                        viewModel.makeWalletData(
                            from: userWalletModel,
                            accountModels: accountModels,
                            entries: userTokensArrays.flatMap { $0 },
                            walletModels: walletModelsArrays.flatMap { $0 }
                        )
                    }
                    .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }

        guard walletDataPublishers.isNotEmpty else { return }

        walletDataPublishers
            .combineLatest()
            .combineLatest(networksSubject)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, output in
                let (walletsData, _) = output
                viewModel.buildUIFromWalletsData(walletsData)
            }
            .store(in: &bag)
    }

    private func buildUIFromWalletsData(_ walletsData: [WalletData]) {
        let factory = MarketsPortfolioTokenItemFactory(
            contextActionsProvider: self,
            contextActionsDelegate: self
        )

        let hasMultipleAccountsCase = walletsData.contains { walletData in
            walletData.accountModels.contains {
                guard case .standard(let cryptoAccounts) = $0 else { return false }
                return cryptoAccounts.state == .multiple
            }
        }

        let shouldAnimate = networks != nil

        if hasMultipleAccountsCase {
            buildAccountsAwareUI(walletsData: walletsData, factory: factory, animated: shouldAnimate)
        } else {
            buildSimpleWalletsUI(walletsData: walletsData, factory: factory, animated: shouldAnimate)
        }

        updateExpandedAction()
    }

    /// Builds accounts-aware UI from wallet data
    private func buildAccountsAwareUI(walletsData: [WalletData], factory: MarketsPortfolioTokenItemFactory, animated: Bool) {
        var allUserWalletsWithAccountsData: [TypeView.UserWalletWithAccountsData] = []
        var allTokenItemViewModels: [MarketsPortfolioTokenItemViewModel] = []

        for walletData in walletsData {
            var accountsWithTokenItems: [TypeView.AccountWithTokenItemsData] = []

            for accountModel in walletData.accountModels {
                guard case .standard(let cryptoAccounts) = accountModel else { continue }

                let accounts = extractAccounts(from: cryptoAccounts)
                let userWalletInfo = makeUserWalletInfo(from: walletData)

                for account in accounts {
                    let viewModels = factory.makeViewModels(
                        coinId: coinId,
                        walletModels: account.walletModelsManager.walletModels,
                        entries: walletData.entries,
                        userWalletInfo: userWalletInfo,
                        namingStyle: .tokenItemName
                    )

                    if viewModels.isNotEmpty {
                        let accountData = TypeView.AccountData(
                            id: account.id.toAnyHashable(),
                            name: account.name,
                            iconInfo: AccountIconViewBuilder.makeAccountIconViewData(accountModel: account)
                        )

                        accountsWithTokenItems.append(
                            .init(accountData: accountData, tokenItems: viewModels)
                        )

                        allTokenItemViewModels.append(contentsOf: viewModels)
                    }
                }
            }

            if accountsWithTokenItems.isNotEmpty {
                allUserWalletsWithAccountsData.append(
                    .init(
                        userWalletId: walletData.userWalletId,
                        userWalletName: walletData.userWalletName,
                        accountsWithTokenItems: accountsWithTokenItems
                    )
                )
            }
        }

        tokenItemViewModels = allTokenItemViewModels
        updateTypeView(
            hasTokens: allTokenItemViewModels.isNotEmpty,
            listStyle: .walletsWithAccounts(allUserWalletsWithAccountsData),
            animated: animated
        )
    }

    /// Builds simple wallets UI from wallet data
    private func buildSimpleWalletsUI(walletsData: [WalletData], factory: MarketsPortfolioTokenItemFactory, animated: Bool) {
        var allUserWalletsWithTokensData: [TypeView.UserWalletWithTokensData] = []
        var allTokenItemViewModels: [MarketsPortfolioTokenItemViewModel] = []

        for walletData in walletsData {
            let viewModels = factory.makeViewModels(
                coinId: coinId,
                walletModels: walletData.walletModels,
                entries: walletData.entries,
                userWalletInfo: makeUserWalletInfo(from: walletData),
                namingStyle: .tokenItemName
            )

            if viewModels.isNotEmpty {
                allUserWalletsWithTokensData.append(
                    .init(
                        userWalletId: walletData.userWalletId,
                        userWalletName: walletData.userWalletName,
                        tokenItems: viewModels
                    )
                )

                allTokenItemViewModels.append(contentsOf: viewModels)
            }
        }

        tokenItemViewModels = allTokenItemViewModels
        updateTypeView(
            hasTokens: allTokenItemViewModels.isNotEmpty,
            listStyle: .justWallets(allUserWalletsWithTokensData),
            animated: animated
        )
    }

    // MARK: - Helper Methods

    /// Extracts all accounts from CryptoAccounts enum (handles both .single and .multiple cases)
    private func extractAccounts(from cryptoAccounts: CryptoAccounts) -> [any CryptoAccountModel] {
        switch cryptoAccounts {
        case .single(let account):
            return [account]
        case .multiple(let accounts):
            return accounts
        }
    }

    /// Creates WalletData from UserWalletModel and components
    private func makeWalletData(
        from userWalletModel: UserWalletModel,
        accountModels: [AccountModel],
        entries: [TokenItem],
        walletModels: [any WalletModel]
    ) -> WalletData {
        WalletData(
            userWalletId: userWalletModel.userWalletId,
            userWalletName: userWalletModel.name,
            accountModels: accountModels,
            entries: entries,
            walletModels: walletModels,
            config: userWalletModel.config
        )
    }

    /// Creates UserWalletInfo from WalletData
    private func makeUserWalletInfo(from walletData: WalletData) -> MarketsPortfolioTokenItemFactory.UserWalletInfo {
        .init(userWalletName: walletData.userWalletName, userWalletId: walletData.userWalletId)
    }

    /// Creates analytics parameters for wallet model actions
    private func makeAnalyticsParams(for walletModel: any WalletModel) -> [Analytics.ParameterKey: String] {
        [
            .source: Analytics.ParameterValue.market.rawValue,
            .token: walletModel.tokenItem.currencySymbol.uppercased(),
            .blockchain: walletModel.tokenItem.blockchain.displayName,
        ]
    }

    /// Determines target type view state based on tokens and support state
    private func determineTypeViewState(
        hasTokens: Bool,
        listStyle: TypeView.ListStyle,
        supportedState: SupportedStateOption
    ) -> TypeView {
        guard !hasTokens else {
            return .list(listStyle)
        }

        switch supportedState {
        case .available:
            return .empty
        case .unavailable:
            return .unavailable
        case .unsupported:
            return .unsupported
        }
    }

    /// Updates typeView based on current state
    private func updateTypeView(hasTokens: Bool, listStyle: TypeView.ListStyle, animated: Bool) {
        if let networks = networks {
            let supportedState = supportedState(networks: networks)
            isAddTokenButtonDisabled = tokenAddedToAllNetworksAndWallets(availableNetworks: networks)

            let targetState = determineTypeViewState(hasTokens: hasTokens, listStyle: listStyle, supportedState: supportedState)

            withAnimation(animated ? .default : nil) {
                typeView = targetState
                isLoadingNetworks = false
            }
        } else if !hasTokens {
            withAnimation(animated ? .default : nil) {
                typeView = .loading
                isLoadingNetworks = true
            }
        }
    }
}

// MARK: - MarketsPortfolioContextActionsProvider

extension MarketsAccountsAwarePortfolioContainerViewModel: MarketsPortfolioContextActionsProvider {
    func buildContextActions(tokenItem: TokenItem, walletModelId: WalletModelId, userWalletId: UserWalletId) -> [TokenActionType] {
        guard let userWalletModel = walletDataProvider.userWalletModels[userWalletId],
              // accounts_fixes_needed_markets
              let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: { $0.id == walletModelId }) else {
            return []
        }

        return TokenActionAvailabilityProvider(userWalletConfig: userWalletModel.config, walletModel: walletModel)
            .buildMarketsTokenContextActions()
    }
}

// MARK: - MarketsPortfolioContextActionsDelegate

extension MarketsAccountsAwarePortfolioContainerViewModel: MarketsPortfolioContextActionsDelegate {
    func showContextAction(for viewModel: MarketsPortfolioTokenItemViewModel) {
        withAnimation {
            tokenWithExpandedQuickActions = (tokenWithExpandedQuickActions === viewModel) ? nil : viewModel
        }
    }

    func didTapContextAction(_ action: TokenActionType, walletModelId: WalletModelId, userWalletId: UserWalletId) {
        guard let userWalletModel = walletDataProvider.userWalletModels[userWalletId],
              // accounts_fixes_needed_markets
              let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: { $0.id == walletModelId }),
              let coordinator else {
            return
        }

        let expressInput = ExpressDependenciesInput(
            userWalletInfo: userWalletModel.userWalletInfo,
            source: walletModel.asExpressInteractorWallet,
            destination: .loadingAndSet
        )

        let sendInput = SendInput(userWalletInfo: userWalletModel.userWalletInfo, walletModel: walletModel)
        let analyticsParams = makeAnalyticsParams(for: walletModel)

        switch action {
        case .buy:
            Analytics.log(event: .marketsChartButtonBuy, params: analyticsParams)
            coordinator.openOnramp(input: sendInput)
        case .receive:
            Analytics.log(event: .marketsChartButtonReceive, params: analyticsParams)
            coordinator.openReceive(walletModel: walletModel)
        case .exchange:
            Analytics.log(event: .marketsChartButtonSwap, params: analyticsParams)
            coordinator.openExchange(input: expressInput)
        case .stake:
            Analytics.log(event: .marketsChartButtonStake, params: analyticsParams)
            if let stakingManager = walletModel.stakingManager {
                coordinator.openStaking(input: sendInput, stakingManager: stakingManager)
            }
        case .hide, .marketsDetails, .send, .sell, .copyAddress:
            break
        }
    }
}

extension MarketsAccountsAwarePortfolioContainerViewModel {
    struct InputData {
        let coinId: String
    }

    enum SupportedStateOption {
        case available
        case unavailable
        case unsupported
    }

    /// Reactive data model emitted from publishers
    struct WalletData {
        let userWalletId: UserWalletId
        let userWalletName: String
        let accountModels: [AccountModel]
        let entries: [TokenItem]
        let walletModels: [any WalletModel]
        let config: UserWalletConfig
    }
}
