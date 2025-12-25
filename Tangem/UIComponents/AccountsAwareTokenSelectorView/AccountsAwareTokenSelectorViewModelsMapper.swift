//
//  AccountsAwareTokenSelectorViewModelsMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

final class AccountsAwareTokenSelectorViewModelsMapper {
    // MARK: - Public

    lazy var wallets: [AccountsAwareTokenSelectorWalletItemViewModel] = walletsProvider.wallets.map { wallet in
        mapToAccountsAwareTokenSelectorWalletItemViewModel(wallet: wallet)
    }

    // MARK: - Dependencies

    private let walletsProvider: any AccountsAwareTokenSelectorWalletsProvider
    private let availabilityProvider: any AccountsAwareTokenSelectorItemAvailabilityProvider

    // MARK: - Internal

    private let searchText: CurrentValueSubject<String, Never> = .init("")
    private let selectedItem: CurrentValueSubject<TokenItem?, Never> = .init(.none)
    private weak var output: (any AccountsAwareTokenSelectorViewModelOutput)?

    private let itemViewModelBuilder: AccountsAwareTokenSelectorItemViewModelBuilder
    private var searchTextCancellable: AnyCancellable?
    private var selectedItemCancellable: AnyCancellable?

    init(
        walletsProvider: any AccountsAwareTokenSelectorWalletsProvider,
        availabilityProvider: any AccountsAwareTokenSelectorItemAvailabilityProvider
    ) {
        self.walletsProvider = walletsProvider
        self.availabilityProvider = availabilityProvider

        itemViewModelBuilder = .init(availabilityProvider: availabilityProvider)
    }

    func setup(with output: (any AccountsAwareTokenSelectorViewModelOutput)?) {
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

private extension AccountsAwareTokenSelectorViewModelsMapper {
    func items(provider: AccountsAwareTokenSelectorCryptoAccountModelItemsProvider) -> [AccountsAwareTokenSelectorItem] {
        var items = provider.items

        if !searchText.value.isEmpty {
            items = items.filter { $0.isMatching(searchText: searchText.value) }
        }

        if let selected = selectedItem.value {
            items = items.filter { $0.walletModel.tokenItem != selected }
        }

        return items
    }

    func itemsPublisher(provider: AccountsAwareTokenSelectorCryptoAccountModelItemsProvider) -> AnyPublisher<[AccountsAwareTokenSelectorItem], Never> {
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
                    return items.filter { $0.walletModel.tokenItem != selected }
                }

                return items
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Mapping

private extension AccountsAwareTokenSelectorViewModelsMapper {
    func mapToAccountsAwareTokenSelectorWalletItemViewModel(wallet: AccountsAwareTokenSelectorWallet) -> AccountsAwareTokenSelectorWalletItemViewModel {
        func mapToViewType(accountType: AccountsAwareTokenSelectorWallet.AccountType) -> AccountsAwareTokenSelectorWalletItemViewModel.ViewType {
            switch accountType {
            case .single(let account):
                let wallet = mapToAccountsAwareTokenSelectorAccountViewModel(
                    header: .wallet(wallet.wallet.name),
                    account: account
                )

                return .wallet(wallet)

            case .multiple(let accounts):
                let accounts = accounts.map { account in
                    let header = AccountsAwareTokenSelectorAccountViewModel.HeaderType.account(
                        icon: AccountModelUtils.UI.iconViewData(accountModel: account.cryptoAccount),
                        name: account.cryptoAccount.name
                    )

                    return mapToAccountsAwareTokenSelectorAccountViewModel(header: header, account: account)
                }

                return .accounts(walletName: wallet.wallet.name, accounts: accounts)
            }
        }

        let viewTypePublisher = wallet.accountsPublisher
            .map { mapToViewType(accountType: $0) }
            .eraseToAnyPublisher()

        return AccountsAwareTokenSelectorWalletItemViewModel(
            viewType: mapToViewType(accountType: wallet.accounts),
            viewTypePublisher: viewTypePublisher
        )
    }

    func mapToAccountsAwareTokenSelectorAccountViewModel(
        header: AccountsAwareTokenSelectorAccountViewModel.HeaderType,
        account: AccountsAwareTokenSelectorAccount
    ) -> AccountsAwareTokenSelectorAccountViewModel {
        let items = items(provider: account.itemsProvider)
            .map { mapToAccountsAwareTokenSelectorItemViewModel(item: $0) }

        let itemsPublisher = itemsPublisher(provider: account.itemsProvider)
            .withWeakCaptureOf(self)
            .map { provider, items in
                items.map { provider.mapToAccountsAwareTokenSelectorItemViewModel(item: $0) }
            }
            .eraseToAnyPublisher()

        return AccountsAwareTokenSelectorAccountViewModel(header: header, items: items, itemsPublisher: itemsPublisher)
    }

    func mapToAccountsAwareTokenSelectorItemViewModel(item: AccountsAwareTokenSelectorItem) -> AccountsAwareTokenSelectorItemViewModel {
        itemViewModelBuilder.mapToAccountsAwareTokenSelectorItemViewModel(item: item) { [weak self] in
            self?.output?.usedDidSelect(item: item)
        }
    }
}
