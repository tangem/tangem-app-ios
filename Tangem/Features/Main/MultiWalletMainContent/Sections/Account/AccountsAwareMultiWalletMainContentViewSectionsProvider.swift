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
import UIKit // [REDACTED_TODO_COMMENT]
import TangemFoundation

final class AccountsAwareMultiWalletMainContentViewSectionsProvider {
    private let userWalletModel: UserWalletModel
    private let cache: ThreadSafeContainer<Cache>
    private let mappingQueue: DispatchQueue

    /// Shared source of truth for both plain and account sections publishers.
    private lazy var commonSectionsPublisher: some Publisher<CommonSectionInput, Never> = makeCommonSectionsPublisher()
    private weak var itemViewModelFactory: MultiWalletMainContentItemViewModelFactory?
    private var purgeCacheSubscription: AnyCancellable?

    init(
        userWalletModel: UserWalletModel
    ) {
        self.userWalletModel = userWalletModel

        mappingQueue = DispatchQueue(
            label: "com.tangem.AccountsAwareMultiWalletMainContentViewSectionsProvider.mappingQueue",
            target: .global(qos: .userInitiated)
        )

        cache = .init(.init())
    }

    private func makeCommonSectionsPublisher() -> some Publisher<CommonSectionInput, Never> {
        let sourcePublisherFactory = TokenSectionsSourcePublisherFactory()
        let cache = cache
        let publisher = userWalletModel
            .accountModelsManager
            .accountModelsPublisher
            .map { $0.cryptoAccounts() }
            .withWeakCaptureOf(self)
            .flatMapLatest { provider, cryptoAccounts -> AnyPublisher<CommonSectionInput, Never> in
                let cryptoAccountModels = Self.extractCryptoAccountModels(from: cryptoAccounts)
                let hasMultipleAccounts = cryptoAccounts.hasMultipleAccounts

                guard cryptoAccountModels.isNotEmpty else {
                    let input = CommonSectionInput(hasMultipleAccounts: hasMultipleAccounts, accountSections: [])

                    return .just(output: input)
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
                            .map { AccountSectionInput(cryptoAccountModel: cryptoAccountModel, sections: $0) }
                    }
                    .combineLatest()
                    .map { CommonSectionInput(hasMultipleAccounts: hasMultipleAccounts, accountSections: $0) }
                    .eraseToAnyPublisher()
            }
            .share(replay: 1)

        subscribeToCachePurgePublisher(publisher)

        return publisher
    }

    private func makeOrGetCachedTokenSectionsAdapter(
        for cryptoAccountModel: any CryptoAccountModel,
        using cache: ThreadSafeContainer<Cache>
    ) -> TokenSectionsAdapter {
        let cacheKey = ObjectIdentifier(cryptoAccountModel)

        if let cachedAdapter: TokenSectionsAdapter = cache.tokenSectionsAdapters[cacheKey] {
            let _ = print("\(#function) called at \(CACurrentMediaTime()) cache_hit_purge")
            return cachedAdapter
        }
        let _ = print("\(#function) called at \(CACurrentMediaTime()) cache_miss_purge")

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

        if let cachedItemViewModel: ExpandableAccountItemViewModel = cache.accountItemViewModels[cacheKey] {
            let _ = print("\(#function) called at \(CACurrentMediaTime()) cache_hit_purge")
            return cachedItemViewModel
        }
        let _ = print("\(#function) called at \(CACurrentMediaTime()) cache_miss_purge")

        let itemViewModel = ExpandableAccountItemViewModel(accountModel: cryptoAccountModel)
        cache.mutate { $0.accountItemViewModels[cacheKey] = itemViewModel }

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
                        _ = print("\(#function) called at \(CACurrentMediaTime()) cache_hit_purge")
                        return cachedViewModel
                    }
                    _ = print("\(#function) called at \(CACurrentMediaTime()) cache_miss_purge")
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
    private func subscribeToCachePurgePublisher(_ publisher: some Publisher<CommonSectionInput, Never>) {
        // Clearing previous subscriptions, shouldn't happen but just in case
        purgeCacheSubscription?.cancel()

        purgeCacheSubscription = publisher
            .withWeakCaptureOf(self)
            .sink { provider, input in
                provider.purgeCache(using: input.accountSections)
            }
    }

    private func purgeCache(using sections: [AccountSectionInput]) {
        _ = print("\(#function) called at \(CACurrentMediaTime()) with accounts")

        // Token item view models are cached per wallet model
        let actualTokenItemViewModelsCacheKeys = sections
            .flatMap(\.sections)
            .flatMap(\.walletModels)
            .map(ObjectIdentifier.init)
            .toSet()

        let tokenItemViewModelsCacheKeysToDelete = cache
            .tokenItemViewModels
            .keys
            .filter { !actualTokenItemViewModelsCacheKeys.contains($0) }

        // Section adapters and account item view models are cached per account
        let actualSectionItemViewModelsCacheKeys = sections
            .map(\.cryptoAccountModel)
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

        purgeCacheIfNeeded(
            tokenItemViewModelsCacheKeysToDelete: tokenItemViewModelsCacheKeysToDelete,
            tokenSectionsAdaptersCacheKeysToDelete: tokenSectionsAdaptersCacheKeysToDelete,
            accountItemViewModelsCacheKeysToDelete: accountItemViewModelsCacheKeysToDelete,
            actualTokenItemViewModelsCacheKeys: actualTokenItemViewModelsCacheKeys,
            actualSectionItemViewModelsCacheKeys: actualSectionItemViewModelsCacheKeys
        )
    }

    private func purgeCacheIfNeeded(
        tokenItemViewModelsCacheKeysToDelete: [ObjectIdentifier],
        tokenSectionsAdaptersCacheKeysToDelete: [ObjectIdentifier],
        accountItemViewModelsCacheKeysToDelete: [ObjectIdentifier],
        actualTokenItemViewModelsCacheKeys: Set<ObjectIdentifier>,
        actualSectionItemViewModelsCacheKeys: Set<ObjectIdentifier>,
    ) {
        guard tokenItemViewModelsCacheKeysToDelete.isNotEmpty
            || tokenSectionsAdaptersCacheKeysToDelete.isNotEmpty
            || accountItemViewModelsCacheKeysToDelete.isNotEmpty
        else {
            return
        }

        cache.mutate { cache in
            let before_tokenItemViewModels = cache.tokenItemViewModels.keys.count // [REDACTED_TODO_COMMENT]
            let before_tokenSectionsAdapters = cache.tokenSectionsAdapters.keys.count // [REDACTED_TODO_COMMENT]
            let before_accountItemViewModels = cache.accountItemViewModels.keys.count // [REDACTED_TODO_COMMENT]
            for key in tokenItemViewModelsCacheKeysToDelete {
                if cache.tokenItemViewModels.keys.contains(key) {
                    _ = print("\(#function) called at \(CACurrentMediaTime()) purging_tokenItemViewModel=\(cache.tokenItemViewModels[key])")
                    cache.tokenItemViewModels.removeValue(forKey: key)
                }
            }
            for key in tokenSectionsAdaptersCacheKeysToDelete {
                if cache.tokenSectionsAdapters.keys.contains(key) {
                    _ = print("\(#function) called at \(CACurrentMediaTime()) purging_tokenSectionsAdapters=\(cache.tokenSectionsAdapters[key])")
                    cache.tokenSectionsAdapters.removeValue(forKey: key)
                }
            }
            for key in accountItemViewModelsCacheKeysToDelete {
                if cache.accountItemViewModels.keys.contains(key) {
                    _ = print("\(#function) called at \(CACurrentMediaTime()) purging_accountItemViewModels=\(cache.accountItemViewModels[key])")
                    cache.accountItemViewModels.removeValue(forKey: key)
                }
            }
            let after_tokenItemViewModels = cache.tokenItemViewModels.keys.count // [REDACTED_TODO_COMMENT]
            let after_tokenSectionsAdapters = cache.tokenSectionsAdapters.keys.count // [REDACTED_TODO_COMMENT]
            let after_accountItemViewModels = cache.accountItemViewModels.keys.count // [REDACTED_TODO_COMMENT]
            _ = print("\(#function) called at \(CACurrentMediaTime()) tokenItemViewModels before=\(before_tokenItemViewModels); actual=\(actualTokenItemViewModelsCacheKeys.count), to_delete=\(tokenItemViewModelsCacheKeysToDelete.count); after=\(after_tokenItemViewModels)")
            _ = print("\(#function) called at \(CACurrentMediaTime()) tokenSectionsAdapters before=\(before_tokenSectionsAdapters); actual=\(actualSectionItemViewModelsCacheKeys.count), to_delete=\(tokenSectionsAdaptersCacheKeysToDelete.count); after=\(after_tokenSectionsAdapters)")
            _ = print("\(#function) called at \(CACurrentMediaTime()) accountItemViewModels before=\(before_accountItemViewModels); actual=\(actualSectionItemViewModelsCacheKeys.count), to_delete=\(accountItemViewModelsCacheKeysToDelete.count); after=\(after_accountItemViewModels)")
        }
    }
}

// MARK: - MultiWalletMainContentViewSectionsProvider protocol conformance

extension AccountsAwareMultiWalletMainContentViewSectionsProvider: MultiWalletMainContentViewSectionsProvider {
    func makePlainSectionsPublisher() -> some Publisher<[MultiWalletMainContentPlainSection], Never> {
        let _ = print("\(#function) called at \(CACurrentMediaTime())")
        let cache = cache

        return commonSectionsPublisher
            .map { input -> [AccountSectionInput] in
                // When there are multiple accounts, we don't need to show plain sections
                // Instead, account sections from `makeAccountSectionsPublisher()` will be used to render multiple accounts
                guard !input.hasMultipleAccounts else {
                    return []
                }

                return input.accountSections
            }
            .withWeakCaptureOf(self)
            .map { provider, input in
                return input.flatMap { provider.convertToSections($0.sections, using: cache) }
            }
            .receiveOnMain()
            .share(replay: 1)
    }

    func makeAccountSectionsPublisher() -> some Publisher<[MultiWalletMainContentAccountSection], Never> {
        let _ = print("\(#function) called at \(CACurrentMediaTime())")
        let cache = cache

        return commonSectionsPublisher
            .map { input -> [AccountSectionInput] in
                // When there are no multiple accounts, we don't need to show sections with accounts
                // Instead, plain sections from `makePlainSectionsPublisher()` will be used to render tokens of a single account
                guard input.hasMultipleAccounts else {
                    return []
                }

                return input.accountSections
            }
            .withWeakCaptureOf(self)
            .map { provider, input in
                return input.map { input in
                    let model = provider.makeOrGetCachedAccountItemViewModel(for: input.cryptoAccountModel)
                    let items = provider.convertToSections(input.sections, using: cache)

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
        /// Keyed by `ObjectIdentifier` of `CryptoAccountModel`.
        var accountItemViewModels: [ObjectIdentifier: ExpandableAccountItemViewModel] = [:]
        /// Keyed by `ObjectIdentifier` of `CryptoAccountModel`.
        var tokenSectionsAdapters: [ObjectIdentifier: TokenSectionsAdapter] = [:]
        /// Keyed by `ObjectIdentifier` of `WalletModel`.
        var tokenItemViewModels: [ObjectIdentifier: TokenItemViewModel] = [:]
    }

    /// Temporary internal-only type representing account section input.
    struct AccountSectionInput {
        let cryptoAccountModel: any CryptoAccountModel
        let sections: [TokenSectionsAdapter.Section]
    }

    /// Temporary internal-only type representing common section input.
    struct CommonSectionInput {
        let hasMultipleAccounts: Bool
        let accountSections: [AccountSectionInput]
    }
}
