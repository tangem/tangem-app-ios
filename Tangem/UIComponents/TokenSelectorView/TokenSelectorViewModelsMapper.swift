//
//  TokenSelectorViewModelsMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class TokenSelectorViewModelsMapper {
    // MARK: - Public

    lazy var wallets: [TokenSelectorWalletItemViewModel] = walletsProvider.wallets.map { wallet in
        mapToTokenSelectorWalletItemViewModel(wallet: wallet)
    }

    private var cache: [TokenSelectorItem: TokenSelectorItemViewModel] = [:]

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

    private let mappingQueue = DispatchQueue(
        label: "com.tangem.TokenSelectorViewModelsMapper.mappingQueue",
        qos: .userInitiated,
        target: .global(qos: .userInitiated)
    )

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

    func setupSelectedItemFilter(selectedItemPublisher: some Publisher<TokenItem?, Never>) {
        selectedItemCancellable = selectedItemPublisher
            .assign(to: \.selectedItem.value, on: self, ownership: .weak)
    }
}

// MARK: - Private

private extension TokenSelectorViewModelsMapper {
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

        let viewTypePublisher = wallet
            .accountsPublisher
            .withWeakCaptureOf(self)
            .map { mapper, accounts in
                return mapper.mapToViewType(accountType: accounts, walletName: walletName, walletId: walletId)
            }
            .eraseToAnyPublisher()

        let isOpen = expandedStateStorage?.isWalletOpen(walletId) ?? true

        return TokenSelectorWalletItemViewModel(
            isOpen: isOpen,
            viewType: mapToViewType(accountType: wallet.accounts, walletName: walletName, walletId: walletId),
            viewTypePublisher: viewTypePublisher,
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

        let itemsPublisher = rawItemsPublisher
            .withWeakCaptureOf(self)
            .receive(on: mappingQueue)
            .map { provider, items in
                items.map { provider.mapToTokenSelectorItemViewModel(item: $0) }
            }
            .eraseToAnyPublisher()

        var expandableViewModel: TokenSelectorExpandableAccountItemViewModel?

        if collapsibleAccounts, case .account = header {
            let accountStateStorage = expandedStateStorage?.makeAccountStateStorage(for: walletId)
                ?? ExpandableAccountItemStateStorageStub(isExpanded: false)

            expandableViewModel = TokenSelectorExpandableAccountItemViewModel(
                account: account.account,
                stateStorage: accountStateStorage,
                itemsCountPublisher: rawItemsPublisher.map(\.count).eraseToAnyPublisher(),
                searchTextPublisher: searchText.eraseToAnyPublisher()
            )
        }

        return TokenSelectorAccountViewModel(
            header: header,
            itemsPublisher: itemsPublisher,
            expandableViewModel: expandableViewModel
        )
    }

    func mapToTokenSelectorItemViewModel(item: TokenSelectorItem) -> TokenSelectorItemViewModel {
        if let cached = cache[item] {
            return cached
        }

        let viewModel = itemViewModelBuilder.mapToTokenSelectorItemViewModel(item: item) { [weak self] in
            self?.output?.userDidSelect(item: item)
        }
        cache[item] = viewModel

        return viewModel
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
}
