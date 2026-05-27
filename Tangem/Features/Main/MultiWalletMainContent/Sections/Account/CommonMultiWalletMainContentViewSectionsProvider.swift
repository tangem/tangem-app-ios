//
//  CommonMultiWalletMainContentViewSectionsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

final class CommonMultiWalletMainContentViewSectionsProvider {
    private typealias EntitiesCache = ThreadSafeContainer<Cache>

    private let userWalletModel: UserWalletModel
    private let manageTokensActionFactory: (any CryptoAccountModel) -> () -> Void
    private let cache: EntitiesCache
    private let mappingQueue: DispatchQueue

    /// Shared source of truth for both plain and account sections publishers.
    private lazy var commonSectionsPublisher: some Publisher<CommonSectionInput, Never> = makeCommonSectionsPublisher()
    private weak var itemViewModelFactory: MultiWalletMainContentItemViewModelFactory?
    private var purgeCacheSubscription: AnyCancellable?

    init(
        userWalletModel: UserWalletModel,
        manageTokensActionFactory: @escaping (any CryptoAccountModel) -> () -> Void
    ) {
        self.userWalletModel = userWalletModel
        self.manageTokensActionFactory = manageTokensActionFactory

        mappingQueue = DispatchQueue(
            label: "com.tangem.CommonMultiWalletMainContentViewSectionsProvider.mappingQueue",
            target: .global(qos: .userInitiated)
        )

        cache = .init(.init())
    }

    private func makeCommonSectionsPublisher() -> some Publisher<CommonSectionInput, Never> {
        let sourcePublisherFactory = TokenSectionsSourcePublisherFactory()
        let cache = cache
        let mappingQueue = mappingQueue
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
                        let tokenSectionsAdapter = Self
                            .makeOrGetCachedTokenSectionsAdapter(for: cryptoAccountModel, using: cache)

                        let tokenSectionsSourcePublisher = sourcePublisherFactory
                            .makeSourcePublisher(for: cryptoAccountModel, in: provider.userWalletModel)

                        let organizedTokensSectionsPublisher = tokenSectionsAdapter
                            .organizedSections(from: tokenSectionsSourcePublisher, on: mappingQueue)

                        return organizedTokensSectionsPublisher
                            .map { AccountSectionInput(cryptoAccountModel: cryptoAccountModel, sections: $0) }
                    }
                    .combineLatest()
                    .map { CommonSectionInput(hasMultipleAccounts: hasMultipleAccounts, accountSections: $0) }
                    .eraseToAnyPublisher()
            }
            .share(replay: 1)

        subscribeToPurgeCache(publisher)

        return publisher
    }

    private static func makeOrGetCachedTokenSectionsAdapter(
        for cryptoAccountModel: any CryptoAccountModel,
        using cache: EntitiesCache
    ) -> TokenSectionsAdapter {
        let cacheKey = ObjectIdentifier(cryptoAccountModel)

        if let cachedAdapter = cache.tokenSectionsAdapters[cacheKey] {
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

    private static func makeOrGetCachedAccountItemViewModel(
        for cryptoAccountModel: any CryptoAccountModel,
        in userWallet: UserWalletModel,
        using cache: EntitiesCache,
        onManageTokensTap: @escaping () -> Void
    ) -> ExpandableAccountItemViewModel {
        let cacheKey = ObjectIdentifier(cryptoAccountModel)

        if let cachedItemViewModel = cache.accountItemViewModels[cacheKey] {
            return cachedItemViewModel
        }

        @Injected(\.expandableAccountItemStateStorageProvider)
        var expandableAccountItemStateStorageProvider: ExpandableAccountItemStateStorageProvider

        let stateStorage = expandableAccountItemStateStorageProvider.makeStateStorage(for: userWallet.userWalletId)
        let itemViewModel = ExpandableAccountItemViewModel(
            accountModel: cryptoAccountModel,
            stateStorage: stateStorage,
            onManageTokensTap: onManageTokensTap
        )

        cache.mutate { $0.accountItemViewModels[cacheKey] = itemViewModel }

        return itemViewModel
    }

    private func convertToSections(
        _ sections: [TokenSectionsAdapter.Section],
        using cache: EntitiesCache
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
                    if let cachedViewModel = cache.tokenItemViewModelsByWalletModel[cacheKey] {
                        return cachedViewModel
                    }
                    let viewModel = itemViewModelFactory.makeTokenItemViewModel(from: item, using: sectionItemsFactory)
                    cache.mutate { $0.tokenItemViewModelsByWalletModel[cacheKey] = viewModel }
                    return viewModel
                case .withoutDerivation(let cacheKey):
                    if let cachedViewModel = cache.tokenItemViewModelsByTokenItem[cacheKey] {
                        return cachedViewModel
                    }
                    let viewModel = itemViewModelFactory.makeTokenItemViewModel(from: item, using: sectionItemsFactory)
                    cache.mutate { $0.tokenItemViewModelsByTokenItem[cacheKey] = viewModel }
                    return viewModel
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
    private func subscribeToPurgeCache(_ publisher: some Publisher<CommonSectionInput, Never>) {
        // Clearing previous subscriptions, shouldn't happen but just in case
        purgeCacheSubscription?.cancel()

        purgeCacheSubscription = publisher
            .withWeakCaptureOf(self)
            .sink { provider, input in
                provider.purgeCache(using: input.accountSections)
            }
    }

    private func purgeCache(using sections: [AccountSectionInput]) {
        var actualTokenItemViewModelsByWalletModelKeys: Set<ObjectIdentifier> = []
        var actualTokenItemViewModelsByTokenItemKeys: Set<TokenItem> = []

        for sectionItem in sections.flatMap(\.sections).flatMap(\.items) {
            switch sectionItem {
            case .default(let walletModel):
                actualTokenItemViewModelsByWalletModelKeys.insert(ObjectIdentifier(walletModel))
            case .withoutDerivation(let tokenItem):
                actualTokenItemViewModelsByTokenItemKeys.insert(tokenItem)
            }
        }

        let tokenItemViewModelsByWalletModelKeysToDelete = cache
            .tokenItemViewModelsByWalletModel
            .keys
            .filter { !actualTokenItemViewModelsByWalletModelKeys.contains($0) }

        let tokenItemViewModelsByTokenItemKeysToDelete = cache
            .tokenItemViewModelsByTokenItem
            .keys
            .filter { !actualTokenItemViewModelsByTokenItemKeys.contains($0) }

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
            tokenItemViewModelsByWalletModelKeysToDelete: tokenItemViewModelsByWalletModelKeysToDelete,
            tokenItemViewModelsByTokenItemKeysToDelete: tokenItemViewModelsByTokenItemKeysToDelete,
            tokenSectionsAdaptersCacheKeysToDelete: tokenSectionsAdaptersCacheKeysToDelete,
            accountItemViewModelsCacheKeysToDelete: accountItemViewModelsCacheKeysToDelete
        )
    }

    private func purgeCacheIfNeeded(
        tokenItemViewModelsByWalletModelKeysToDelete: [ObjectIdentifier],
        tokenItemViewModelsByTokenItemKeysToDelete: [TokenItem],
        tokenSectionsAdaptersCacheKeysToDelete: [ObjectIdentifier],
        accountItemViewModelsCacheKeysToDelete: [ObjectIdentifier]
    ) {
        guard tokenItemViewModelsByWalletModelKeysToDelete.isNotEmpty
            || tokenItemViewModelsByTokenItemKeysToDelete.isNotEmpty
            || tokenSectionsAdaptersCacheKeysToDelete.isNotEmpty
            || accountItemViewModelsCacheKeysToDelete.isNotEmpty
        else {
            return
        }

        cache.mutate { cache in
            for key in tokenItemViewModelsByWalletModelKeysToDelete {
                cache.tokenItemViewModelsByWalletModel.removeValue(forKey: key)
            }
            for key in tokenItemViewModelsByTokenItemKeysToDelete {
                cache.tokenItemViewModelsByTokenItem.removeValue(forKey: key)
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

extension CommonMultiWalletMainContentViewSectionsProvider: MultiWalletMainContentViewSectionsProvider {
    func makePlainSectionsPublisher() -> some Publisher<[MultiWalletMainContentPlainSection], Never> {
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
                    let model = Self.makeOrGetCachedAccountItemViewModel(
                        for: input.cryptoAccountModel,
                        in: provider.userWalletModel,
                        using: cache,
                        onManageTokensTap: provider.manageTokensActionFactory(input.cryptoAccountModel)
                    )
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

private extension CommonMultiWalletMainContentViewSectionsProvider {
    /// A cache for various inner types used in `CommonMultiWalletMainContentViewSectionsProvider`.
    final class Cache {
        /// Keyed by `ObjectIdentifier` of `CryptoAccountModel`.
        var accountItemViewModels: [ObjectIdentifier: ExpandableAccountItemViewModel] = [:]
        /// Keyed by `ObjectIdentifier` of `CryptoAccountModel`.
        var tokenSectionsAdapters: [ObjectIdentifier: TokenSectionsAdapter] = [:]
        /// Keyed by `ObjectIdentifier` of `WalletModel`, used for `.default` section items (reference semantics).
        var tokenItemViewModelsByWalletModel: [ObjectIdentifier: TokenItemViewModel] = [:]
        /// Keyed by `TokenItem`, used for `.withoutDerivation` section items (value semantics).
        var tokenItemViewModelsByTokenItem: [TokenItem: TokenItemViewModel] = [:]
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
