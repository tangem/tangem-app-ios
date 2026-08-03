//
//  EarnOpportunitiesViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation
import TangemUI

final class EarnOpportunitiesViewModel: ObservableObject {
    // MARK: - Typealias

    typealias SelectionScopePublisher = ForYouAccountSelectionResolver.SelectionScopePublisher

    // MARK: - Dependencies

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.earnAnalyticsProvider) private var earnAnalyticsProvider: EarnAnalyticsProvider

    // MARK: - Properties

    private let mapper = EarnOpportunitiesMapper()
    private let apyResolver = EarnApyResolver()
    private let iconBuilder = TokenIconInfoBuilder()
    private let suggestionsProvider: EarnDataProvider = CommonEarnDataService(
        ethereumP2PFilter: CommonEarnEthereumP2PFilter()
    )
    private let suggestions = CurrentValueSubject<EarnOpportunitiesMapper.SuggestionsState, Never>(.loading)
    private let selectionScopePublisher: SelectionScopePublisher
    private let analyticsLogger: EarnOpportunitiesAnalyticsLogger

    private weak var router: EarnOpportunitiesRoutable?

    private var expandedIds: Set<String> = []
    // Tap routing needs the domain models the mapper output drops. Keyed by a wallet-qualified holding row id.
    private var holdingContexts: [String: HoldingContext] = [:]
    private var bag: Set<AnyCancellable> = []

    // MARK: - Publishers

    @Published private(set) var state: ViewState = .loading

    // MARK: - Init

    init(
        selectionScopePublisher: SelectionScopePublisher,
        analyticsLogger: EarnOpportunitiesAnalyticsLogger,
        router: EarnOpportunitiesRoutable? = nil
    ) {
        self.selectionScopePublisher = selectionScopePublisher
        self.analyticsLogger = analyticsLogger
        self.router = router
        bind()
        fetchSuggestions()
    }

    /// Preview/testing entry point: fixed state, no data pipeline.
    init(state: ViewState) {
        selectionScopePublisher = Empty().eraseToAnyPublisher()
        analyticsLogger = ForYouAnalyticsLoggerStub()
        self.state = state
    }

    // MARK: - Internal methods

    func toggle(_ id: String) {
        guard case .content(let content) = state,
              case .accounts(let accounts) = content.list,
              accounts.contains(where: { $0.id == id }) else {
            return
        }

        expandedIds.formSymmetricDifference([id])
        state = state.expanding(expandedIds)
    }

    @MainActor
    func exploreAllTokensTapped() {
        analyticsLogger.logExploreAllTokens()
        router?.openSeeAllEarn()
    }

    @MainActor
    func selectHolding(_ rowId: String) {
        guard let context = holdingContexts[rowId],
              let product = apyResolver.resolve(for: context.walletModel)?.product else {
            return
        }

        analyticsLogger.logEarnTokenOpened(tokenItem: context.walletModel.tokenItem, product: product)

        switch product {
        case .staking:
            router?.openEarnStaking(walletModel: context.walletModel, userWalletModel: context.userWalletModel)
        case .yieldSupply:
            router?.openEarnYield(walletModel: context.walletModel, userWalletModel: context.userWalletModel)
        }
    }

    @MainActor
    func selectSuggestion(_ token: EarnTokenModel) {
        earnAnalyticsProvider.logOpportunitySelected(
            token: token.symbol,
            blockchain: token.networkName,
            source: EarnOpportunitySource.forYou.rawValue
        )

        let models = userWalletRepository.models.filter { !$0.isUserWalletLocked }
        let resolution = EarnTokenInWalletResolver().resolve(earnToken: token, userWalletModels: models)
        router?.routeEarnSuggestion(resolution)
    }
}

// MARK: - Data flow

private extension EarnOpportunitiesViewModel {
    typealias StateOutput = (state: ViewState, contexts: [String: HoldingContext])

    func bind() {
        selectedModelPublisher()
            // Rebuild the state stream only when wallet presence flips, not on every active-wallet switch.
            .map { $0 != nil }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .flatMapLatest { viewModel, hasSelectedWallet in
                viewModel.statePublisher(hasSelectedWallet: hasSelectedWallet)
            }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, output in
                // Contexts refresh on every emission — an equal-looking state can still carry new model instances.
                viewModel.holdingContexts = output.contexts

                let newState = output.state.expanding(viewModel.expandedIds)
                if viewModel.state != newState {
                    viewModel.state = newState
                }
            }
            .store(in: &bag)
    }

    func selectedModelPublisher() -> AnyPublisher<UserWalletModel?, Never> {
        userWalletRepository.eventProvider
            .withWeakCaptureOf(self)
            .map { viewModel, _ in
                viewModel.userWalletRepository.selectedModel
            }
            .prepend(userWalletRepository.selectedModel)
            .removeDuplicates {
                $0?.userWalletId == $1?.userWalletId
            }
            .eraseToAnyPublisher()
    }

    /// Carries the per-row wallet models the mapper output drops, so taps can route.
    func statePublisher(hasSelectedWallet: Bool) -> AnyPublisher<StateOutput, Never> {
        guard hasSelectedWallet else {
            // No wallet → suggestions variant.
            return suggestions
                .withWeakCaptureOf(self)
                .map { viewModel, suggestions in
                    viewModel.makeStateOutput(suggestions: suggestions)
                }
                .eraseToAnyPublisher()
        }

        // Shared once: rates, balance, and the main combine reuse a single cross-wallet subscription.
        let accountsPublisher = selectedAccountsPublisher().share(replay: 1).eraseToAnyPublisher()

        // Rates load independently of balances, so re-map on their changes too.
        let ratesTrigger = accountsPublisher
            .map { accounts -> AnyPublisher<Void, Never> in
                let statePublishers = accounts
                    .flatMap(\.walletModels)
                    .flatMap { walletModel in
                        [
                            walletModel.stakingManager?.statePublisher.mapToVoid().eraseToAnyPublisher(),
                            walletModel.yieldModuleManager?.statePublisher.mapToVoid().eraseToAnyPublisher(),
                        ].compactMap { $0 }
                    }

                return Publishers.MergeMany(statePublishers).eraseToAnyPublisher()
            }
            .switchToLatest()
            .prepend(())

        let balanceTrigger = accountsPublisher
            .map { accounts -> AnyPublisher<Void, Never> in
                guard !accounts.isEmpty else {
                    return Just(()).eraseToAnyPublisher()
                }

                return accounts
                    .map { $0.account.fiatTotalBalanceProvider.totalBalancePublisher }
                    .combineLatest()
                    .mapToVoid()
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .prepend(())

        // Rates, balances, and currency only trigger a re-map; their values aren't read here.
        let remapTrigger = Publishers.CombineLatest3(
            ratesTrigger,
            balanceTrigger,
            AppSettings.shared.$selectedCurrencyCode.mapToVoid()
        )

        return Publishers.CombineLatest(accountsPublisher, suggestions)
            .combineLatest(remapTrigger) { data, _ in data }
            .withWeakCaptureOf(self)
            .map { viewModel, data in
                viewModel.makeStateOutput(accounts: data.0, suggestions: data.1)
            }
            .eraseToAnyPublisher()
    }

    func makeStateOutput(
        accounts: [AccountWithWalletModels],
        suggestions: EarnOpportunitiesMapper.SuggestionsState
    ) -> StateOutput {
        let candidates = accounts.compactMap(candidate)
        let state = mapper.map(
            accounts: candidates,
            suggestions: suggestions,
            isResolvingRates: Self.isResolvingRates(accounts)
        )

        return StateOutput(state: state, contexts: holdingContextsByRowId(accounts))
    }

    /// No wallet → suggestions only.
    func makeStateOutput(suggestions: EarnOpportunitiesMapper.SuggestionsState) -> StateOutput {
        let state = mapper.map(accounts: [], suggestions: suggestions, isResolvingRates: false)
        return StateOutput(state: state, contexts: [:])
    }

    func holdingContextsByRowId(_ accounts: [AccountWithWalletModels]) -> [String: HoldingContext] {
        var result: [String: HoldingContext] = [:]

        for account in accounts {
            for walletModel in account.walletModels {
                let rowId = Self.holdingRowId(userWalletId: account.userWalletModel.userWalletId, walletModel: walletModel)
                result[rowId] = HoldingContext(
                    walletModel: walletModel,
                    userWalletModel: account.userWalletModel
                )
            }
        }

        return result
    }

    /// `walletModel.id.id` excludes the wallet, so it collides across wallets holding the same token — prefix wallet id.
    static func holdingRowId(userWalletId: UserWalletId, walletModel: any WalletModel) -> String {
        "\(userWalletId.stringValue)_\(walletModel.id.id)"
    }

    /// Carries each account's owning wallet so a holding tap routes to the right wallet.
    func selectedAccountsPublisher() -> AnyPublisher<[AccountWithWalletModels], Never> {
        selectionScopePublisher
            .map(\.selected)
            .map { selected -> AnyPublisher<[AccountWithWalletModels], Never> in
                guard !selected.isEmpty else {
                    return Just([]).eraseToAnyPublisher()
                }

                return selected
                    .map { pair in
                        pair.account.walletModelsManager.walletModelsPublisher
                            .map { AccountWithWalletModels(account: pair.account, walletModels: $0, userWalletModel: pair.wallet) }
                    }
                    .combineLatest()
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    func candidate(from item: AccountWithWalletModels) -> EarnOpportunitiesMapper.AccountCandidate? {
        let holdings: [EarnOpportunitiesMapper.HoldingCandidate] = item.walletModels.compactMap { walletModel in
            guard let apyInfo = apyResolver.resolve(for: walletModel) else {
                return nil
            }

            let tokenItem = walletModel.tokenItem
            return EarnOpportunitiesMapper.HoldingCandidate(
                id: Self.holdingRowId(userWalletId: item.userWalletModel.userWalletId, walletModel: walletModel),
                assetKey: EarnOpportunitiesMapper.AssetKey(
                    currencyId: tokenItem.currencyId ?? walletModel.id.id,
                    networkId: tokenItem.networkId
                ),
                tokenIconInfo: iconBuilder.build(from: tokenItem, isCustom: walletModel.isCustom),
                currencyName: tokenItem.name,
                networkName: tokenItem.networkName,
                cryptoBalance: walletModel.availableBalanceProvider.balanceType.value,
                fiatBalance: walletModel.fiatAvailableBalanceProvider.balanceType.value,
                apyInfo: apyInfo
            )
        }

        guard holdings.isNotEmpty else {
            return nil
        }

        return EarnOpportunitiesMapper.AccountCandidate(
            // Wallet id in the key: the same account index (persistent id) repeats across wallets.
            id: "\(item.userWalletModel.userWalletId.stringValue)_\(item.account.id.toPersistentIdentifier())",
            name: item.account.name,
            icon: item.account.icon,
            holdings: holdings
        )
    }

    /// A manager mid-load can make a "nothing eligible" verdict false.
    static func isResolvingRates(_ items: [AccountWithWalletModels]) -> Bool {
        items.flatMap(\.walletModels).contains { walletModel in
            if walletModel.stakingManager?.state.isLoading == true {
                return true
            }

            if walletModel.yieldModuleManager?.state?.state.isLoading == true {
                return true
            }

            return false
        }
    }

    struct AccountWithWalletModels {
        let account: any CryptoAccountModel
        let walletModels: [any WalletModel]
        let userWalletModel: any UserWalletModel
    }

    /// The domain models a holding tap needs to route staking/yield — the mapper output drops them.
    struct HoldingContext {
        let walletModel: any WalletModel
        let userWalletModel: any UserWalletModel
    }
}

// MARK: - Suggestions

private extension EarnOpportunitiesViewModel {
    /// One-shot fetch; a failure leaves suggestions empty.
    func fetchSuggestions() {
        suggestionsProvider.eventPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, event in
                switch event {
                case .appendedItems(let items, _):
                    viewModel.suggestions.send(.loaded(items))
                case .failedToFetchData:
                    viewModel.suggestions.send(.failed)
                case .loading, .idle, .startInitialFetch, .cleared:
                    break
                }
            }
            .store(in: &bag)

        suggestionsProvider.fetch(with: EarnDataFilter())
    }
}

// MARK: - Expansion

private extension EarnOpportunitiesViewModel.ViewState {
    func expanding(_ expandedIds: Set<String>) -> Self {
        guard case .content(let content) = self, case .accounts(let accounts) = content.list else {
            return self
        }

        let updated = accounts.map { $0.updating(isExpanded: expandedIds.contains($0.id)) }
        return .content(.init(subtitle: content.subtitle, list: .accounts(updated)))
    }
}
