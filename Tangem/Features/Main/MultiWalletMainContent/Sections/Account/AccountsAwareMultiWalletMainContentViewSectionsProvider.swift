//
//  AccountsAwareMultiWalletMainContentViewSectionsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

final class AccountsAwareMultiWalletMainContentViewSectionsProvider {
    private typealias AccountSection = (any CryptoAccountModel, [TokenSectionsAdapter.Section])

    private let userWalletModel: UserWalletModel
    private let plainSectionsСache: ThreadSafeContainer<Cache>
    private let accountSectionsСache: ThreadSafeContainer<Cache>
    private let mappingQueue: DispatchQueue

    private lazy var aggregatedCryptoAccountsPublisher = userWalletModel
        .accountModelsManager
        .accountModelsPublisher
        .map { $0.cryptoAccounts() }
        .share(replay: 1)

    private var plainSectionsBag: Set<AnyCancellable> = []
    private var accountSectionsBag: Set<AnyCancellable> = []

    private weak var itemViewModelFactory: MultiWalletMainContentItemViewModelFactory?

    init(
        userWalletModel: UserWalletModel
    ) {
        self.userWalletModel = userWalletModel

        mappingQueue = DispatchQueue(
            label: "com.tangem.AccountsAwareMultiWalletMainContentViewSectionsProvider.mappingQueue",
            target: .global(qos: .userInitiated)
        )

        plainSectionsСache = .init(.init())
        accountSectionsСache = .init(.init())
    }

    private func makeOrGetCachedTokenSectionsAdapter(
        for cryptoAccountModel: any CryptoAccountModel,
        using cache: ThreadSafeContainer<Cache>
    ) -> TokenSectionsAdapter {
        let cacheKey = ObjectIdentifier(cryptoAccountModel)

        if let cachedAdapter: TokenSectionsAdapter = cache.tokenSectionsAdapters[cacheKey] {
            return cachedAdapter
        }

        let userTokensManager = cryptoAccountModel.userTokensManager
        let optionsManager = OrganizeTokensOptionsManager(
            userTokensReorderer: userTokensManager
        )
        let tokenSectionsAdapter = TokenSectionsAdapter(
            userTokensManager: userTokensManager,
            optionsProviding: optionsManager,
            preservesLastSortedOrderOnSwitchToDragAndDrop: false
        )
        cache.mutate { $0.tokenSectionsAdapters[cacheKey] = tokenSectionsAdapter }

        return tokenSectionsAdapter
    }

    private func makeOrGetCachedAccountItemViewModel(for cryptoAccountModel: any CryptoAccountModel) -> ExpandableAccountItemViewModel {
        let cacheKey = ObjectIdentifier(cryptoAccountModel)

        if let cachedItemViewModel: ExpandableAccountItemViewModel = accountSectionsСache.accountItemViewModels[cacheKey] {
            return cachedItemViewModel
        }

        let itemViewModel = ExpandableAccountItemViewModel(accountModel: cryptoAccountModel)
        accountSectionsСache.mutate { $0.accountItemViewModels[cacheKey] = itemViewModel }

        return itemViewModel
    }

    private func convertToSections(
        _ sections: [TokenSectionsAdapter.Section],
        using cache: ThreadSafeContainer<Cache>
    ) -> [MultiWalletMainContentPlainSection] {
        if sections.count == 1, sections[0].items.isEmpty {
            return []
        }

        guard let itemViewModelFactory = itemViewModelFactory else {
            return []
        }

        let sectionItemsFactory = MultiWalletSectionItemsFactory()

        return sections.enumerated().map { index, section in
            let sectionViewModel = sectionItemsFactory.makeSectionViewModel(from: section.model, atIndex: index)
            let itemViewModels = section.items.map { item in
                switch item {
                case .default(let walletModel):
                    let cacheKey = ObjectIdentifier(walletModel)
                    if let cachedViewModel: TokenItemViewModel = cache.tokenItemViewModels[cacheKey] {
                        return cachedViewModel
                    }
                    let viewModel = itemViewModelFactory.makeTokenItemViewModel(from: item, using: sectionItemsFactory)
                    cache.mutate { $0.tokenItemViewModels[cacheKey] = viewModel }
                    return viewModel
                case .withoutDerivation:
                    return itemViewModelFactory.makeTokenItemViewModel(from: item, using: sectionItemsFactory)
                }
            }

            return MultiWalletMainContentPlainSection(model: sectionViewModel, items: itemViewModels)
        }
    }

    private static func extractCryptoAccountModels(from cryptoAccounts: [CryptoAccounts]) -> [any CryptoAccountModel] {
        return cryptoAccounts
            .reduce(into: []) { result, cryptoAccount in
                switch cryptoAccount {
                case .single(let cryptoAccountModel):
                    result.append(cryptoAccountModel)
                case .multiple(let cryptoAccountModels):
                    result.append(contentsOf: cryptoAccountModels)
                }
            }
    }

    /// This subscription is needed for purging the cache.
    private func subscribeToPlainSectionsPublisher(_ publisher: some Publisher<[[TokenSectionsAdapter.Section]], Never>) {
        // Clearing previous subscriptions, shouldn't happen but just in case
        plainSectionsBag.removeAll()
        // [REDACTED_TODO_COMMENT]
    }

    /// This subscription is needed for purging the cache.
    private func subscribeToAccountSectionsPublisher(_ publisher: some Publisher<[AccountSection], Never>) {
        // Clearing previous subscriptions, shouldn't happen but just in case
        accountSectionsBag.removeAll()

        publisher
            .withWeakCaptureOf(self)
            .sink { provider, sections in
                provider.purgeCache(using: sections)
            }
            .store(in: &accountSectionsBag)
    }

    private func purgeCache(using sections: [AccountSection]) {
        let cache = accountSectionsСache

        let actualTokenItemViewModelsCacheKeys = sections
            .flatMap(\.1)
            .flatMap(\.walletModels)
            .map(ObjectIdentifier.init)
            .toSet()

        let tokenItemViewModelsCacheKeysToDelete = cache
            .tokenItemViewModels
            .keys
            .filter { !actualTokenItemViewModelsCacheKeys.contains($0) }

        // Section adapters and account item view models are cached per account
        let actualSectionItemViewModelsCacheKeys = sections
            .map(\.0)
            .map(ObjectIdentifier.init)
            .toSet()

        let tokenSectionsAdaptersCacheKeysToDelete = cache
            .tokenSectionsAdapters
            .keys
            .filter { !actualSectionItemViewModelsCacheKeys.contains($0) }

        let accountItemViewModelsCacheKeysToDelete = cache
            .accountItemViewModels
            .keys
            .filter { !actualSectionItemViewModelsCacheKeys.contains($0) }

        guard tokenItemViewModelsCacheKeysToDelete.isNotEmpty
            || tokenSectionsAdaptersCacheKeysToDelete.isNotEmpty
            || accountItemViewModelsCacheKeysToDelete.isNotEmpty
        else {
            return
        }

        cache.mutate { cache in
            for key in tokenItemViewModelsCacheKeysToDelete {
                cache.tokenItemViewModels.removeValue(forKey: key)
            }
            for key in tokenSectionsAdaptersCacheKeysToDelete {
                cache.tokenSectionsAdapters.removeValue(forKey: key)
            }
            for key in accountItemViewModelsCacheKeysToDelete {
                cache.accountItemViewModels.removeValue(forKey: key)
            }
        }
    }
}

// MARK: - MultiWalletMainContentViewSectionsProvider protocol conformance

extension AccountsAwareMultiWalletMainContentViewSectionsProvider: MultiWalletMainContentViewSectionsProvider {
    func makePlainSectionsPublisher() -> some Publisher<[MultiWalletMainContentPlainSection], Never> {
        let sourcePublisherFactory = TokenSectionsSourcePublisherFactory()
        let cache = plainSectionsСache
        let publisher = aggregatedCryptoAccountsPublisher
            .map { cryptoAccounts -> [any CryptoAccountModel] in
                // When there are no multiple accounts, we don't need to show plain sections
                // Instead, account sections from `makeAccountSectionsPublisher()` will be used to render multiple accounts
                if cryptoAccounts.hasMultipleAccounts {
                    return []
                }

                return Self.extractCryptoAccountModels(from: cryptoAccounts)
            }
            .withWeakCaptureOf(self)
            .flatMapLatest { provider, cryptoAccountModels -> AnyPublisher<[[TokenSectionsAdapter.Section]], Never> in
                guard cryptoAccountModels.isNotEmpty else {
                    return .just(output: [])
                }

                return cryptoAccountModels
                    .map { cryptoAccountModel in
                        let tokenSectionsAdapter = provider
                            .makeOrGetCachedTokenSectionsAdapter(for: cryptoAccountModel, using: cache)

                        let tokenSectionsSourcePublisher = sourcePublisherFactory
                            .makeSourcePublisher(for: cryptoAccountModel)

                        let organizedTokensSectionsPublisher = tokenSectionsAdapter
                            .organizedSections(from: tokenSectionsSourcePublisher, on: provider.mappingQueue)

                        return organizedTokensSectionsPublisher
                    }
                    .combineLatest()
                    .eraseToAnyPublisher()
            }
            .share(replay: 1)

        subscribeToPlainSectionsPublisher(publisher)

        return publisher
            .withWeakCaptureOf(self)
            .map { provider, sections in
                return sections.flatMap { provider.convertToSections($0, using: cache) }
            }
            .receiveOnMain()
            .share(replay: 1)
    }

    func makeAccountSectionsPublisher() -> some Publisher<[MultiWalletMainContentAccountSection], Never> {
        let sourcePublisherFactory = TokenSectionsSourcePublisherFactory()
        let cache = accountSectionsСache
        let publisher = aggregatedCryptoAccountsPublisher
            .map { cryptoAccounts -> [any CryptoAccountModel] in
                // When there are no multiple accounts, we don't need to show sections with accounts
                // Instead, plain sections from `makePlainSectionsPublisher()` will be used to render tokens of a single account
                guard cryptoAccounts.hasMultipleAccounts else {
                    return []
                }

                return Self.extractCryptoAccountModels(from: cryptoAccounts)
            }
            .withWeakCaptureOf(self)
            .flatMapLatest { provider, cryptoAccountModels -> AnyPublisher<[AccountSection], Never> in
                guard cryptoAccountModels.isNotEmpty else {
                    return .just(output: [])
                }

                return cryptoAccountModels
                    .map { cryptoAccountModel in
                        let tokenSectionsAdapter = provider
                            .makeOrGetCachedTokenSectionsAdapter(for: cryptoAccountModel, using: cache)

                        let tokenSectionsSourcePublisher = sourcePublisherFactory
                            .makeSourcePublisher(for: cryptoAccountModel)

                        let organizedTokensSectionsPublisher = tokenSectionsAdapter
                            .organizedSections(from: tokenSectionsSourcePublisher, on: provider.mappingQueue)

                        return organizedTokensSectionsPublisher
                            .map { (cryptoAccountModel, $0) }
                    }
                    .combineLatest()
                    .eraseToAnyPublisher()
            }
            .share(replay: 1)

        subscribeToAccountSectionsPublisher(publisher)

        return publisher
            .withWeakCaptureOf(self)
            .map { provider, input in
                return input.map { cryptoAccountModel, sections in
                    let model = provider.makeOrGetCachedAccountItemViewModel(for: cryptoAccountModel)
                    let items = provider.convertToSections(sections, using: cache)

                    return MultiWalletMainContentAccountSection(model: model, items: items)
                }
            }
            .receiveOnMain()
            .share(replay: 1)
    }

    func configure(with itemViewModelFactory: any MultiWalletMainContentItemViewModelFactory) {
        self.itemViewModelFactory = itemViewModelFactory
    }
}

// MARK: - Auxiliary types

private extension AccountsAwareMultiWalletMainContentViewSectionsProvider {
    /// A cache for various inner types used in `AccountsAwareMultiWalletMainContentViewSectionsProvider`.
    final class Cache {
        var accountItemViewModels: [ObjectIdentifier: ExpandableAccountItemViewModel] = [:]
        var tokenItemViewModels: [ObjectIdentifier: TokenItemViewModel] = [:]
        var tokenSectionsAdapters: [ObjectIdentifier: TokenSectionsAdapter] = [:]
    }
}
