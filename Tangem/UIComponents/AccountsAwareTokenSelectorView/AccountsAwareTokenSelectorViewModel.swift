//
//  AccountsAwareTokenSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemAccounts
import TangemFoundation
import TangemMacro

final class AccountsAwareTokenSelectorViewModel: ObservableObject {
    @Published var searchText: String = ""

    @Published private(set) var wallets: [AccountsAwareTokenSelectorWalletItemViewModel]
    @Published private(set) var contentVisibility: ContentVisibility = .visible(itemsCount: 0)

    private let walletsProvider: any AccountsAwareTokenSelectorWalletsProvider
    private let availabilityProvider: any AccountsAwareTokenSelectorItemAvailabilityProvider

    private let viewModelsMapper: AccountsAwareTokenSelectorViewModelsMapper

    init(
        walletsProvider: any AccountsAwareTokenSelectorWalletsProvider,
        availabilityProvider: any AccountsAwareTokenSelectorItemAvailabilityProvider
    ) {
        self.walletsProvider = walletsProvider
        self.availabilityProvider = availabilityProvider

        viewModelsMapper = AccountsAwareTokenSelectorViewModelsMapper(
            walletsProvider: walletsProvider,
            availabilityProvider: availabilityProvider
        )

        wallets = viewModelsMapper.wallets

        viewModelsMapper.setupSearchable(searchTextPublisher: $searchText.eraseToAnyPublisher())
        bind()
    }

    func setup(with output: AccountsAwareTokenSelectorViewModelOutput?) {
        viewModelsMapper.setup(with: output)
    }

    func setup(directionPublisher: some Publisher<AccountsAwareTokenSelectorItemSwapAvailabilityProvider.SwapDirection?, Never>) {
        guard let availabilityProvider = (availabilityProvider as? AccountsAwareTokenSelectorItemSwapAvailabilityProvider) else {
            assertionFailure("setup(directionPublisher:) called with incompatible availabilityProvider")
            return
        }

        availabilityProvider.setup(directionPublisher: directionPublisher)
        viewModelsMapper.setupSelectedItemFilter(selectedItemPublisher: directionPublisher.map { $0?.tokenItem })
    }

    private func bind() {
        // Collect items count from all wallets and compute visibility
        wallets
            .map { $0.$viewType.flatMapLatest { $0.itemsCount } }
            .combineLatest()
            .map { counts -> ContentVisibility in
                let totalCount = counts.sum()
                return totalCount == 0 ? .empty : .visible(itemsCount: totalCount)
            }
            .removeDuplicates()
            .assign(to: &$contentVisibility)
    }
}

// MARK: - ContentVisibility

extension AccountsAwareTokenSelectorViewModel {
    @CaseFlagable
    enum ContentVisibility: Equatable {
        case visible(itemsCount: Int)
        case empty
    }
}
