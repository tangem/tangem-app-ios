//
//  TokenSelectorViewModelsMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemUI

final class TokenSelectorViewModelsMapper {
    // MARK: - Public

    lazy var wallets: [TokenSelectorWalletItemViewModel] = walletsProvider.wallets.map { wallet in
        mapToTokenSelectorWalletItemViewModel(wallet: wallet)
    }

    // MARK: - Dependencies

    private let walletsProvider: any TokenSelectorWalletsProvider
    private let availabilityProvider: any TokenSelectorItemAvailabilityProvider
    private let collapsibleAccounts: Bool
    private let expandedStateStorage: (any TokenSelectorExpandedStateStorage)?

    // MARK: - Internal

    private let searchText: CurrentValueSubject<String, Never> = .init("")
    private let selectedItem: CurrentValueSubject<TokenItem?, Never> = .init(.none)
    private weak var output: (any TokenSelectorViewModelOutput)?

    private let itemViewModelBuilder: TokenSelectorItemViewModelBuilder
    private var searchTextCancellable: AnyCancellable?
    private var selectedItemCancellable: AnyCancellable?

    init(
        walletsProvider: any TokenSelectorWalletsProvider,
        availabilityProvider: any TokenSelectorItemAvailabilityProvider,
        collapsibleAccounts: Bool = false,
        expandedStateStorage: (any TokenSelectorExpandedStateStorage)? = nil
    ) {
        self.walletsProvider = walletsProvider
        self.availabilityProvider = availabilityProvider
        self.collapsibleAccounts = collapsibleAccounts
        self.expandedStateStorage = expandedStateStorage

        itemViewModelBuilder = .init(availabilityProvider: availabilityProvider)
    }

    func setup(with output: (any TokenSelectorViewModelOutput)?) {
        self.output = output
    }

    func setupSearchable(searchTextPublisher: some Publisher<String, Never>) {
        searchTextCancellable = searchTextPublisher
            .assign(to: \.searchText.value, on: self, ownership: .weak)
    }

    func setInitialSelectedItem(_ item: TokenItem?) {
        selectedItem.value = item
    }

    func setupSelectedItemFilter(selectedItemPublisher: some Publisher<TokenItem?, Never>) {
        selectedItemCancellable = selectedItemPublisher
            .assign(to: \.selectedItem.value, on: self, ownership: .weak)
    }
}

// MARK: - Private

private extension TokenSelectorViewModelsMapper {
    func items(provider: TokenSelectorAccountModelItemsProvider) -> [TokenSelectorItem] {
        var items = provider.items

        if !searchText.value.isEmpty {
            items = items.filter { $0.isMatching(searchText: searchText.value) }
        }

        if let selected = selectedItem.value {
            items = items.filter { $0.tokenItem != selected }
        }

        return items
    }

    func itemsPublisher(provider: TokenSelectorAccountModelItemsProvider) -> AnyPublisher<[TokenSelectorItem], Never> {
        provider
            .itemsPublisher
            // 1. Filter `searchText`
            .combineLatest(searchText.map { $0.trimmed() }.removeDuplicates())
            .map { items, searchText in
                if searchText.isEmpty {
                    return items
                }

                return items.filter { $0.isMatching(searchText: searchText) }
            }
            // 2. Filter `selectedItem`
            .combineLatest(selectedItem.removeDuplicates())
            .map { items, selected in
                if let selected {
                    return items.filter { $0.tokenItem != selected }
                }

                return items
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Mapping

private extension TokenSelectorViewModelsMapper {
    func mapToTokenSelectorWalletItemViewModel(wallet: TokenSelectorWallet) -> TokenSelectorWalletItemViewModel {
        let walletName = wallet.wallet.name
        let walletId = wallet.wallet.id

        let isOpen = expandedStateStorage?.isWalletOpen(walletId) ?? true

        return TokenSelectorWalletItemViewModel(
            walletId: walletId,
            walletName: walletName,
            isOpen: isOpen,
            viewType: mapToViewType(accountType: wallet.accounts, walletName: walletName, walletId: walletId),
            onOpenStateChange: { [expandedStateStorage] open in
                expandedStateStorage?.setWalletOpen(open, for: walletId)
            }
        )
    }

    func mapToTokenSelectorAccountViewModel(
        header: TokenSelectorAccountViewModel.HeaderType,
        account: TokenSelectorAccount,
        walletId: UserWalletId
    ) -> TokenSelectorAccountViewModel {
        let rawItemsPublisher = itemsPublisher(provider: account.itemsProvider)

        let items = items(provider: account.itemsProvider)
            .map { mapToTokenSelectorItemViewModel(item: $0) }

        let itemsPublisher = rawItemsPublisher
            .withWeakCaptureOf(self)
            .map { provider, items in
                items.map { provider.mapToTokenSelectorItemViewModel(item: $0) }
            }
            .eraseToAnyPublisher()

        var expandableViewModel: TokenSelectorExpandableAccountItemViewModel?

        if collapsibleAccounts, case .account = header {
            let accountStateStorage = expandedStateStorage?.makeAccountStateStorage(for: walletId)
                ?? ExpandableAccountItemStateStorageStub(isExpanded: false)

            let initialFilteredItems = self.items(provider: account.itemsProvider)
            let initialFilteredBalance = Self.filteredBalance(from: initialFilteredItems)

            let filteredBalancePublisher = rawItemsPublisher
                .flatMapLatest { items -> AnyPublisher<LoadableBalanceView.State, Never> in
                    guard !items.isEmpty else {
                        return Just(.empty).eraseToAnyPublisher()
                    }

                    return items
                        .map { item in
                            item.fiatBalanceProvider.balanceTypePublisher
                                .map { TokenBalanceTypesCombiner.Balance(item: item.tokenItem, balance: $0) }
                        }
                        .combineLatest()
                        .map { balances in
                            let state = TokenBalanceTypesCombiner().mapToTotalBalance(balances: balances)
                            return LoadableBalanceViewStateBuilder().buildTotalBalance(state: state)
                        }
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()

            expandableViewModel = TokenSelectorExpandableAccountItemViewModel(
                account: account.account,
                stateStorage: accountStateStorage,
                initialItemsCount: items.count,
                itemsCountPublisher: rawItemsPublisher.map(\.count).eraseToAnyPublisher(),
                searchTextPublisher: searchText.eraseToAnyPublisher(),
                initialFilteredBalance: initialFilteredBalance,
                filteredBalancePublisher: filteredBalancePublisher
            )
        }

        return TokenSelectorAccountViewModel(
            header: header,
            items: items,
            itemsPublisher: itemsPublisher,
            expandableViewModel: expandableViewModel
        )
    }

    func mapToTokenSelectorItemViewModel(item: TokenSelectorItem) -> TokenSelectorItemViewModel {
        itemViewModelBuilder.mapToTokenSelectorItemViewModel(item: item) { [weak self] in
            self?.output?.userDidSelect(item: item)
        }
    }

    func mapToViewType(
        accountType: TokenSelectorWallet.AccountType,
        walletName: String,
        walletId: UserWalletId
    ) -> TokenSelectorWalletItemViewModel.ViewType {
        switch accountType {
        case .single(let account):
            let wallet = mapToTokenSelectorAccountViewModel(
                header: .wallet(walletName),
                account: account,
                walletId: walletId
            )

            return .wallet(wallet)

        case .multiple(let accounts):
            let accounts = accounts.map { account in
                let header = TokenSelectorAccountViewModel.HeaderType.account(
                    icon: AccountModelUtils.UI.iconViewData(accountModel: account.account),
                    name: account.account.name
                )

                return mapToTokenSelectorAccountViewModel(header: header, account: account, walletId: walletId)
            }

            return .accounts(walletName: walletName, accounts: accounts)
        }
    }

    static func filteredBalance(from items: [TokenSelectorItem]) -> LoadableBalanceView.State {
        let balances = items.map {
            TokenBalanceTypesCombiner.Balance(item: $0.tokenItem, balance: $0.fiatBalanceProvider.balanceType)
        }
        let state = TokenBalanceTypesCombiner().mapToTotalBalance(balances: balances)
        return LoadableBalanceViewStateBuilder().buildTotalBalance(state: state)
    }
}
