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
    // MARK: - Dependencies

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Published

    @Published private(set) var state: ViewState = .loading

    // MARK: - Properties

    private let mapper = EarnOpportunitiesMapper()
    private let apyResolver = EarnApyResolver()
    private let iconBuilder = TokenIconInfoBuilder()
    private let suggestionsProvider: EarnDataProvider = CommonEarnDataService(
        ethereumP2PFilter: CommonEarnEthereumP2PFilter()
    )
    private let suggestions = CurrentValueSubject<EarnOpportunitiesMapper.SuggestionsState, Never>(.loading)
    private let onExploreAllTokens: @MainActor () -> Void

    private var expandedIds: Set<String> = []
    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(onExploreAllTokens: @MainActor @escaping () -> Void = {}) {
        self.onExploreAllTokens = onExploreAllTokens
        bind()
        fetchSuggestions()
    }

    /// Preview/testing entry point: fixed state, no data pipeline.
    init(state: ViewState, onExploreAllTokens: @MainActor @escaping () -> Void = {}) {
        self.onExploreAllTokens = onExploreAllTokens
        self.state = state
    }

    // MARK: - Methods

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
        onExploreAllTokens()
    }
}

// MARK: - Data flow

private extension EarnOpportunitiesViewModel {
    func bind() {
        selectedModelPublisher()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .flatMapLatest { viewModel, selectedModel in
                viewModel.statePublisher(forNewlySelected: selectedModel)
            }
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                // Applied on main; the off-main mapping must not touch `expandedIds`.
                viewModel.state = state.expanding(viewModel.expandedIds)
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

    /// New wallet selection: drops the previous expansion, then derives its state stream.
    func statePublisher(forNewlySelected selectedModel: UserWalletModel?) -> AnyPublisher<ViewState, Never> {
        expandedIds.removeAll()
        return statePublisher(for: selectedModel)
    }

    /// Combines accounts, rates, balance, suggestions, and currency into the state.
    func statePublisher(for selectedModel: UserWalletModel?) -> AnyPublisher<ViewState, Never> {
        guard let selectedModel else {
            // No wallet → suggestions variant.
            return suggestions
                .withWeakCaptureOf(self)
                .map { viewModel, suggestions in
                    viewModel.mapper.map(accounts: [], suggestions: suggestions, isResolvingRates: false)
                }
                .eraseToAnyPublisher()
        }

        let accountsPublisher = Self.accountModelsPublisher(from: selectedModel.accountModelsManager)

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

        // Rates, balances, and currency only trigger a re-map; their values aren't read here.
        let remapTrigger = Publishers.CombineLatest3(
            ratesTrigger,
            selectedModel.totalBalancePublisher.mapToVoid(),
            AppSettings.shared.$selectedCurrencyCode.mapToVoid()
        )

        return Publishers.CombineLatest(accountsPublisher, suggestions)
            .combineLatest(remapTrigger) { data, _ in data }
            .withWeakCaptureOf(self)
            .map { viewModel, data in
                let (accounts, suggestions) = data
                let candidates = accounts.compactMap { viewModel.candidate(from: $0) }

                return viewModel.mapper.map(
                    accounts: candidates,
                    suggestions: suggestions,
                    isResolvingRates: Self.isResolvingRates(accounts)
                )
            }
            .eraseToAnyPublisher()
    }

    static func accountModelsPublisher(
        from accountModelsManager: AccountModelsManager
    ) -> AnyPublisher<[AccountWithWalletModels], Never> {
        accountModelsManager
            .cryptoAccountModelsPublisher
            .flatMapLatest { cryptoAccounts -> AnyPublisher<[AccountWithWalletModels], Never> in
                guard cryptoAccounts.isNotEmpty else {
                    return Just([]).eraseToAnyPublisher()
                }

                return cryptoAccounts
                    .map { account in
                        account.walletModelsManager.walletModelsPublisher
                            .map { AccountWithWalletModels(account: account, walletModels: $0) }
                    }
                    .combineLatest()
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func candidate(from item: AccountWithWalletModels) -> EarnOpportunitiesMapper.AccountCandidate? {
        let holdings: [EarnOpportunitiesMapper.HoldingCandidate] = item.walletModels.compactMap { walletModel in
            guard let apyInfo = apyResolver.resolve(for: walletModel) else {
                return nil
            }

            let tokenItem = walletModel.tokenItem
            return EarnOpportunitiesMapper.HoldingCandidate(
                id: walletModel.id.id,
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
            id: "\(item.account.id.toPersistentIdentifier())",
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
