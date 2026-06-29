//
//  MarketsPortfolioContainerViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import SwiftUI
import BlockchainSdk
import TangemFoundation
import TangemAccounts
import TangemUI

/// Copy-pasted and adapted for accounts `MarketsPortfolioContainerViewModel`
final class MarketsPortfolioContainerViewModel: ObservableObject {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    // MARK: - Published Properties

    @Published private(set) var isAddTokenButtonDisabled: Bool = true
    @Published private(set) var isLoadingNetworks: Bool = false
    @Published private(set) var typeView: TypeView = .loading
    @Published private(set) var tokenItemViewModels: [MarketsPortfolioTokenItemViewModel] = []
    @Published private(set) var tokenWithExpandedQuickActions: MarketsPortfolioTokenItemViewModel?
    @Published private(set) var portfolioBlockState: PortfolioBlockState = .loading
    @Published private(set) var isAddButtonVisible: Bool = false

    private var bag = Set<AnyCancellable>()
    private var balanceCancellables = Set<AnyCancellable>()
    private var portfolioBlockStateCancellable: AnyCancellable?
    private var addButtonVisibilityCancellable: AnyCancellable?
    private var matchedWalletModels: [any WalletModel] = []
    private var hasMultiCurrencyWallet: Bool = false
    @Published private var totalFiatBalanceText: String?

    // MARK: - Private Properties

    private let walletDataProvider: MarketsWalletDataProvider
    private weak var coordinator: MarketsPortfolioContainerRoutable?
    private var addTokenTapAction: (() -> Void)?

    private let coinId: String
    private let coinName: String
    private let coinSymbol: String

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
        coinName = inputData.coinName
        coinSymbol = inputData.coinSymbol
        self.walletDataProvider = walletDataProvider
        self.coordinator = coordinator
        self.addTokenTapAction = addTokenTapAction

        bind()
    }

    // MARK: - Public Implementation

    func onAddTapAction() {
        addTokenTapAction?()
    }

    func onAddFundsTap() {
        coordinator?.openAddFundsTokenList(
            walletModels: matchedWalletModels,
            walletDataProvider: walletDataProvider
        )
    }

    @MainActor
    func onExpandTap() {
        let iconURL = IconURLBuilder().tokenIconURL(id: coinId, size: .large)
        let inputData = MarketsAddTokenFlowConfigurationFactory.InputData(
            coinId: coinId,
            coinName: coinName,
            coinSymbol: coinSymbol,
            networks: networks ?? []
        )
        coordinator?.openMatchedTokenList(
            walletModels: matchedWalletModels,
            iconURL: iconURL,
            addTokenInputData: inputData,
            walletDataProvider: walletDataProvider
        )
    }

    func update(networks: [NetworkModel]) {
        networksSubject.send(networks)
    }

    private func supportedState(networks: [NetworkModel]) -> SupportedStateOption {
        guard networks.isNotEmpty else {
            return .unsupported
        }

        if NetworkSupportChecker.hasAnySupportedNetwork(
            networks: networks,
            userWalletModels: walletDataProvider.userWalletModels
        ) {
            return .available
        }

        return .unavailable
    }

    private func areTokenItemsAddedInAllAccounts(availableNetworks: [NetworkModel]) -> Bool {
        TokenAdditionChecker.areTokenItemsAddedInAllAccounts(
            userWalletModels: walletDataProvider.userWalletModels,
            tokenItemsFactory: { [coinId, coinName, coinSymbol] account, supportedBlockchains in
                MarketsTokenItemsProvider.calculateTokenItems(
                    coinId: coinId,
                    coinName: coinName,
                    coinSymbol: coinSymbol,
                    networks: availableNetworks,
                    supportedBlockchains: supportedBlockchains,
                    cryptoAccount: account
                )
            }
        )
    }

    private func updateExpandedAction() {
        let singleElement = tokenItemViewModels.singleElement
        let oldTokenWithExpandedQuickActions = tokenWithExpandedQuickActions
        tokenWithExpandedQuickActions = singleElement?.hasZeroBalance == true ? singleElement : nil

        // SwiftUI bug workaround: sometimes update of the `tokenWithExpandedQuickActions` published property
        // doesn't trigger the view update (`MarketsPortfolioContainerView.listView`).
        // Assigning custom `id` to that list view doesn't work and adding a proper `Equatable`
        // implementation for the `MarketsPortfolioTokenItemViewModel` view model doesn't help either.
        // So, we need to manually trigger view update by sending `objectWillChange`
        if oldTokenWithExpandedQuickActions !== tokenWithExpandedQuickActions {
            objectWillChange.send()
        }
    }

    // MARK: - Reactive Bindings

    /// Binds to user wallet models list changes
    private func bind() {
        userWalletModelsListSubscription = walletDataProvider.userWalletModelsPublisher
            .sink(receiveValue:
                weakify(self, forFunction: MarketsPortfolioContainerViewModel.bindToUserWalletUpdates(userWalletModels:))
            )

        bindPortfolioBlockState()
        bindAddButtonVisibility()
    }

    private func bindAddButtonVisibility() {
        addButtonVisibilityCancellable = Publishers.CombineLatest($typeView, $isAddTokenButtonDisabled)
            .map { [weak self] typeView, isAddTokenButtonDisabled in
                guard let self, hasMultiCurrencyWallet else { return false }
                switch typeView {
                case .empty, .list:
                    return !isAddTokenButtonDisabled
                case .loading, .unsupported, .unavailable:
                    return false
                }
            }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: \.isAddButtonVisible, on: self, ownership: .weak)
    }

    private func bindPortfolioBlockState() {
        portfolioBlockStateCancellable = Publishers.CombineLatest3($typeView, $tokenItemViewModels, $totalFiatBalanceText)
            .map { [weak self] typeView, tokenItems, balanceText -> PortfolioBlockState in
                guard let self else { return .hidden }
                return resolvePortfolioBlockState(typeView: typeView, tokenItems: tokenItems, balanceText: balanceText)
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: \.portfolioBlockState, on: self, ownership: .weak)
    }

    private func resolvePortfolioBlockState(
        typeView: TypeView,
        tokenItems: [MarketsPortfolioTokenItemViewModel],
        balanceText: String?
    ) -> PortfolioBlockState {
        switch typeView {
        case .loading:
            return .loading

        case .unsupported, .unavailable:
            return .hidden

        case .empty:
            guard hasMultiCurrencyWallet, !isAddTokenButtonDisabled else { return .hidden }
            return .addToken

        case .list:
            return .content(.init(
                balanceText: balanceText,
                tokensInPortfolioCount: tokenItems.count
            ))
        }
    }

    private func rebindMatchedBalances(matchedWalletModelIds: Set<WalletModelId>, allWalletModels: [any WalletModel]) {
        balanceCancellables.removeAll()

        let matched = allWalletModels.filter { matchedWalletModelIds.contains($0.id) }
        matchedWalletModels = matched

        guard !matched.isEmpty else {
            totalFiatBalanceText = nil
            return
        }

        totalFiatBalanceText = formatTotal(from: matched.map(\.fiatTotalTokenBalanceProvider.balanceType))

        let publishers = matched.map { $0.fiatTotalTokenBalanceProvider.balanceTypePublisher }
        publishers
            .combineLatest()
            .map { [weak self] balanceTypes -> String? in
                self?.formatTotal(from: balanceTypes)
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: \.totalFiatBalanceText, on: self, ownership: .weak)
            .store(in: &balanceCancellables)
    }

    private func formatTotal(from balanceTypes: [TokenBalanceType]) -> String {
        let total = balanceTypes.reduce(Decimal.zero) { partial, balanceType in
            partial + (balanceType.value ?? .zero)
        }
        return BalanceFormatter().formatFiatBalance(total)
    }

    private func bindToUserWalletUpdates(userWalletModels: [UserWalletModel]) {
        bag.removeAll()

        let walletDataPublishers = userWalletModels.map { userWalletModel in
            userWalletModel
                .accountModelsManager
                .accountModelsPublisher
                .flatMap { accountModels -> AnyPublisher<WalletData, Never> in
                    let cryptoAccounts = Self.extractCryptoAccountModels(from: accountModels)

                    let walletModelsPublishers = cryptoAccounts.map(\.walletModelsManager.walletModelsPublisher)
                    let userTokensPublishers = cryptoAccounts.map(\.userTokensManager.userTokensPublisher)

                    let combinedWalletModelsPublisher = walletModelsPublishers.combineLatest()
                    let combinedUserTokensPublishers = userTokensPublishers.combineLatest()

                    return Publishers.CombineLatest(
                        combinedWalletModelsPublisher,
                        combinedUserTokensPublishers
                    )
                    .map { walletModelsArrays, userTokensArrays in
                        Self.makeWalletData(
                            from: userWalletModel,
                            accountModels: accountModels,
                            flattenedTokenItems: userTokensArrays.flatMap { $0 },
                            walletModels: walletModelsArrays.flatMap { $0 }
                        )
                    }
                    .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }

        guard walletDataPublishers.isNotEmpty else {
            resetToEmptyState()
            return
        }

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

    private func resetToEmptyState() {
        balanceCancellables.removeAll()
        matchedWalletModels = []
        hasMultiCurrencyWallet = false
        isAddTokenButtonDisabled = true
        totalFiatBalanceText = nil
        tokenItemViewModels = []
        typeView = .loading
        isLoadingNetworks = false
    }

    private func buildUIFromWalletsData(_ walletsData: [WalletData]) {
        let factory = MarketsPortfolioTokenItemFactory(
            contextActionsProvider: self,
            contextActionsDelegate: self
        )

        let hasMultipleAccounts = walletsData.contains { walletData in
            walletData.accountModels.cryptoAccounts().hasMultipleAccounts
        }

        hasMultiCurrencyWallet = walletsData.contains { $0.config.hasFeature(.multiCurrency) }
        let allWalletModels = walletsData.flatMap(\.walletModels)

        let shouldAnimate = networks != nil

        if hasMultipleAccounts {
            buildUI(walletsData: walletsData, factory: factory, allWalletModels: allWalletModels, animated: shouldAnimate)
        } else {
            buildSimpleWalletsUI(walletsData: walletsData, factory: factory, allWalletModels: allWalletModels, animated: shouldAnimate)
        }

        updateExpandedAction()
    }

    /// Builds accounts-aware UI from wallet data
    private func buildUI(walletsData: [WalletData], factory: MarketsPortfolioTokenItemFactory, allWalletModels: [any WalletModel], animated: Bool) {
        var allUserWalletsWithAccountsData: [TypeView.UserWalletWithAccountsData] = []
        var allTokenItemViewModels: [MarketsPortfolioTokenItemViewModel] = []

        for walletData in walletsData {
            var accountsWithTokenItems: [TypeView.AccountWithTokenItemsData] = []
            let userWalletInfo = makeUserWalletInfo(from: walletData)

            for account in Self.extractCryptoAccountModels(from: walletData.accountModels) {
                let viewModels = factory.makeViewModels(
                    coinId: coinId,
                    walletModels: account.walletModelsManager.walletModels,
                    entries: account.userTokensManager.userTokens,
                    userWalletInfo: userWalletInfo
                )

                if viewModels.isNotEmpty {
                    let accountData = TypeView.AccountData(
                        id: account.id.toAnyHashable(),
                        name: account.name,
                        iconInfo: AccountModelUtils.UI.iconViewData(accountModel: account)
                    )

                    accountsWithTokenItems.append(
                        .init(accountData: accountData, tokenItems: viewModels)
                    )

                    allTokenItemViewModels.append(contentsOf: viewModels)
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

        rebindMatchedBalances(
            matchedWalletModelIds: Set(allTokenItemViewModels.map(\.walletModelId)),
            allWalletModels: allWalletModels
        )
        tokenItemViewModels = allTokenItemViewModels
        updateTypeView(
            hasTokens: allTokenItemViewModels.isNotEmpty,
            listStyle: .walletsWithAccounts(allUserWalletsWithAccountsData),
            animated: animated
        )
    }

    /// Builds simple wallets UI from wallet data
    private func buildSimpleWalletsUI(walletsData: [WalletData], factory: MarketsPortfolioTokenItemFactory, allWalletModels: [any WalletModel], animated: Bool) {
        var allUserWalletsWithTokensData: [TypeView.UserWalletWithTokensData] = []
        var allTokenItemViewModels: [MarketsPortfolioTokenItemViewModel] = []

        for walletData in walletsData {
            let viewModels = factory.makeViewModels(
                coinId: coinId,
                walletModels: walletData.walletModels,
                entries: walletData.flattenedTokenItems,
                userWalletInfo: makeUserWalletInfo(from: walletData)
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

        rebindMatchedBalances(
            matchedWalletModelIds: Set(allTokenItemViewModels.map(\.walletModelId)),
            allWalletModels: allWalletModels
        )
        tokenItemViewModels = allTokenItemViewModels
        updateTypeView(
            hasTokens: allTokenItemViewModels.isNotEmpty,
            listStyle: .justWallets(allUserWalletsWithTokensData),
            animated: animated
        )
    }

    // MARK: - Helper Methods

    private static func extractCryptoAccountModels(from accountModels: [AccountModel]) -> [any CryptoAccountModel] {
        return accountModels
            .cryptoAccounts()
            .reduce(into: []) { result, cryptoAccount in
                switch cryptoAccount {
                case .single(let cryptoAccountModel):
                    result.append(cryptoAccountModel)
                case .multiple(let cryptoAccountModels):
                    result.append(contentsOf: cryptoAccountModels)
                }
            }
    }

    private static func makeWalletData(
        from userWalletModel: UserWalletModel,
        accountModels: [AccountModel],
        flattenedTokenItems: [TokenItem],
        walletModels: [any WalletModel]
    ) -> WalletData {
        WalletData(
            userWalletId: userWalletModel.userWalletId,
            userWalletName: userWalletModel.name,
            accountModels: accountModels,
            flattenedTokenItems: flattenedTokenItems,
            walletModels: walletModels,
            config: userWalletModel.config
        )
    }

    private func makeUserWalletInfo(from walletData: WalletData) -> MarketsPortfolioTokenItemFactory.UserWalletInfo {
        .init(userWalletName: walletData.userWalletName, userWalletId: walletData.userWalletId)
    }

    private func makeAnalyticsParams(for walletModel: any WalletModel) -> [Analytics.ParameterKey: String] {
        [
            .source: Analytics.ParameterValue.market.rawValue,
            .token: walletModel.tokenItem.currencySymbol.uppercased(),
            .blockchain: walletModel.tokenItem.blockchain.displayName,
        ]
    }

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

    private func updateTypeView(hasTokens: Bool, listStyle: TypeView.ListStyle, animated: Bool) {
        if let networks {
            let supportedState = supportedState(networks: networks)
            isAddTokenButtonDisabled = areTokenItemsAddedInAllAccounts(availableNetworks: networks)

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

extension MarketsPortfolioContainerViewModel: MarketsPortfolioContextActionsProvider {
    func buildContextActions(tokenItem: TokenItem, walletModelId: WalletModelId, userWalletId: UserWalletId) -> [TokenActionType] {
        guard let userWalletModel = walletDataProvider.userWalletModels[userWalletId] else {
            return []
        }

        let walletModels = AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)

        guard let walletModel = walletModels.first(where: { $0.id == walletModelId }) else {
            return []
        }

        return TokenActionAvailabilityProvider(userWalletInfo: userWalletModel.userWalletInfo, walletModel: walletModel)
            .buildMarketsTokenContextActions()
    }
}

// MARK: - MarketsPortfolioContextActionsDelegate

extension MarketsPortfolioContainerViewModel: MarketsPortfolioContextActionsDelegate {
    func showContextAction(for viewModel: MarketsPortfolioTokenItemViewModel) {
        withAnimation {
            tokenWithExpandedQuickActions = (tokenWithExpandedQuickActions === viewModel) ? nil : viewModel
        }
    }

    func didTapContextAction(_ action: TokenActionType, walletModelId: WalletModelId, userWalletId: UserWalletId) {
        guard
            let userWalletModel = walletDataProvider.userWalletModels[userWalletId],
            let coordinator
        else {
            return
        }

        let walletModels = AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)

        guard let walletModel = walletModels.first(where: { $0.id == walletModelId }) else {
            return
        }

        let sendInput = SendInput(userWalletInfo: userWalletModel.userWalletInfo, walletModel: walletModel)
        let analyticsParams = makeAnalyticsParams(for: walletModel)

        let availabilityProvider = TokenActionAvailabilityProvider(
            userWalletInfo: userWalletModel.userWalletInfo,
            walletModel: walletModel
        )
        let availabilityAlertBuilder = TokenActionAvailabilityAlertBuilder()

        switch action {
        case .buy:
            Analytics.log(event: .marketsChartButtonBuy, params: analyticsParams)
            if let unavailableAlert = availabilityAlertBuilder.alert(for: availabilityProvider.buyAvailablity) {
                alertPresenter.present(alert: unavailableAlert)
                return
            }

            coordinator.openOnramp(input: sendInput, parameters: .none)
        case .receive:
            Analytics.log(event: .marketsChartButtonReceive, params: analyticsParams)
            if let unavailableAlert = availabilityAlertBuilder.alert(
                for: availabilityProvider.receiveAvailability,
                blockchain: walletModel.tokenItem.blockchain
            ) {
                alertPresenter.present(alert: unavailableAlert)
                return
            }

            coordinator.openReceive(userWalletInfo: userWalletModel.userWalletInfo, walletModel: walletModel)
        case .exchange:
            Analytics.log(event: .marketsChartButtonSwap, params: analyticsParams)

            let helper = SwapPredefinedParametersHelper()
            guard let parameters = helper.makeParameters(
                walletModel: walletModel,
                userWalletInfo: userWalletModel.userWalletInfo,
                position: .automatic
            ) else {
                return
            }

            Task { @MainActor in
                coordinator.openSwap(input: parameters, destination: walletModel.tokenItem)
            }
        case .stake:
            Analytics.log(event: .marketsChartButtonStake, params: analyticsParams)
            if let stakingManager = walletModel.stakingManager {
                coordinator.openStaking(input: sendInput, stakingManager: stakingManager)
            }
        case .yield:
            Analytics.log(event: .marketsChartButtonYieldMode, params: analyticsParams)
            if let yieldModuleManager = walletModel.yieldModuleManager {
                coordinator.openYield(input: sendInput, yieldModuleManager: yieldModuleManager)
            }
        case .hide, .marketsDetails, .send, .sell, .copyAddress:
            break
        }
    }
}

extension MarketsPortfolioContainerViewModel {
    struct InputData {
        let coinId: String
        let coinName: String
        let coinSymbol: String
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
        let flattenedTokenItems: [TokenItem]
        let walletModels: [any WalletModel]
        let config: UserWalletConfig
    }

    enum PortfolioBlockState: Equatable {
        case hidden
        case loading
        case addToken
        case content(ContentData)

        struct ContentData: Equatable {
            let balanceText: String?
            let tokensInPortfolioCount: Int
        }

        var isVisible: Bool {
            switch self {
            case .hidden, .loading: false
            case .addToken, .content: true
            }
        }
    }
}
