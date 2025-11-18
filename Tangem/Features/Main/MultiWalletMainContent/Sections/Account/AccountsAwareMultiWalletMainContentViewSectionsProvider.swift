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

final class AccountsAwareMultiWalletMainContentViewSectionsProvider {
    private let userWalletModel: UserWalletModel
    private let cache: Cache // [REDACTED_TODO_COMMENT]
    private let mappingQueue: DispatchQueue

    private lazy var aggregatedCryptoAccountsPublisher = userWalletModel
        .accountModelsManager
        .accountModelsPublisher
        .map { $0.cryptoAccounts() }
        .share(replay: 1)

    private var bag: Set<AnyCancellable> = []

    private weak var itemViewModelFactory: MultiWalletMainContentItemViewModelFactory?

    init(
        userWalletModel: UserWalletModel
    ) {
        self.userWalletModel = userWalletModel

        mappingQueue = DispatchQueue(
            label: "com.tangem.AccountsAwareMultiWalletMainContentViewSectionsProvider.mappingQueue",
            target: .global(qos: .userInitiated)
        )

        let cachingQueue = DispatchQueue(
            label: "com.tangem.AccountsAwareMultiWalletMainContentViewSectionsProvider.cachingQueue",
            attributes: .concurrent,
            target: .global(qos: .userInitiated)
        )

        cache = Cache(workingQueue: cachingQueue)
    }

    private func makeOrGetCachedTokenSectionsAdapter(for cryptoAccountModel: any CryptoAccountModel) -> TokenSectionsAdapter {
        let cacheKey = ObjectIdentifier(cryptoAccountModel)

        if let cachedAdapter: TokenSectionsAdapter = cache[cacheKey] {
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
        cache[cacheKey] = tokenSectionsAdapter

        return tokenSectionsAdapter
    }

    private func makeOrGetCachedAccountItemViewModel(
        for cryptoAccountModel: any CryptoAccountModel
    ) -> ExpandableAccountItemViewModel {
        let cacheKey = ObjectIdentifier(cryptoAccountModel)

        if let cachedItemViewModel: ExpandableAccountItemViewModel = cache[cacheKey] {
            return cachedItemViewModel
        }

        let itemViewModel = ExpandableAccountItemViewModel(accountModel: cryptoAccountModel)
        cache[cacheKey] = itemViewModel

        return itemViewModel
    }

    private func convertToSections(
        _ sections: [TokenSectionsAdapter.Section]
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
                    // Fetching existing cached View Model for this Wallet Model, if available
                    let cacheKey = ObjectIdentifier(walletModel)
                    if let cachedViewModel: TokenItemViewModel = cache[cacheKey] {
                        return cachedViewModel
                    }
                    let viewModel = itemViewModelFactory.makeTokenItemViewModel(from: item, using: sectionItemsFactory)
                    cache[cacheKey] = viewModel
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
}

// MARK: - MultiWalletMainContentViewSectionsProvider protocol conformance

extension AccountsAwareMultiWalletMainContentViewSectionsProvider: MultiWalletMainContentViewSectionsProvider {
    func makePlainSectionsPublisher() -> some Publisher<[MultiWalletMainContentPlainSection], Never> {
        let sourcePublisherFactory = TokenSectionsSourcePublisherFactory()

        return aggregatedCryptoAccountsPublisher
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
                            .makeOrGetCachedTokenSectionsAdapter(for: cryptoAccountModel)

                        let tokenSectionsSourcePublisher = sourcePublisherFactory
                            .makeSourcePublisher(for: cryptoAccountModel)

                        let organizedTokensSectionsPublisher = tokenSectionsAdapter
                            .organizedSections(from: tokenSectionsSourcePublisher, on: provider.mappingQueue)

                        return organizedTokensSectionsPublisher
                    }
                    .combineLatest()
                    .eraseToAnyPublisher()
            }
            .withWeakCaptureOf(self)
            .map { provider, sections in
                return sections.flatMap(provider.convertToSections(_:))
            }
            .receiveOnMain()
            .share(replay: 1)
    }

    func makeAccountSectionsPublisher() -> some Publisher<[MultiWalletMainContentAccountSection], Never> {
        let sourcePublisherFactory = TokenSectionsSourcePublisherFactory()

        return aggregatedCryptoAccountsPublisher
            .map { cryptoAccounts -> [any CryptoAccountModel] in
                // When there are no multiple accounts, we don't need to show sections with accounts
                // Instead, plain sections from `makePlainSectionsPublisher()` will be used to render tokens of a single account
                guard cryptoAccounts.hasMultipleAccounts else {
                    return []
                }

                return Self.extractCryptoAccountModels(from: cryptoAccounts)
            }
            .withWeakCaptureOf(self)
            .flatMapLatest { provider, cryptoAccountModels -> AnyPublisher<[(any CryptoAccountModel, [TokenSectionsAdapter.Section])], Never> in
                guard cryptoAccountModels.isNotEmpty else {
                    return .just(output: [])
                }

                return cryptoAccountModels
                    .map { cryptoAccountModel in
                        let tokenSectionsAdapter = provider
                            .makeOrGetCachedTokenSectionsAdapter(for: cryptoAccountModel)

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
            .withWeakCaptureOf(self)
            .map { provider, input in
                return input.map { cryptoAccountModel, sections in
                    let model = provider.makeOrGetCachedAccountItemViewModel(for: cryptoAccountModel)
                    let items = provider.convertToSections(sections)

                    return MultiWalletMainContentAccountSection(model: model, items: items)
                }
            }
            .receiveOnMain()
            .share(replay: 1)
    }

    func setup(with itemViewModelFactory: any MultiWalletMainContentItemViewModelFactory) {
        self.itemViewModelFactory = itemViewModelFactory
    }
}

// MARK: - Auxiliary types

private extension AccountsAwareMultiWalletMainContentViewSectionsProvider {
    // A cache for various types used in `AccountsAwareMultiWalletMainContentViewSectionsProvider`.
    // Each type is cached separately, in its own inner storage.

    final class Cache {
        /// Unfortunately, parameter packs in generic types are only available in iOS 17 or newer, therefore we have to use `Any` here
        private var outerStorage: [ObjectIdentifier: Any] = [:]
        private let workingQueue: DispatchQueue

        init(workingQueue: DispatchQueue) {
            self.workingQueue = workingQueue
        }

        subscript<Key, Value>(key: Key) -> Value? where Key: Hashable {
            get {
                workingQueue.sync {
                    let innerStorage: [Key: Value]? = innerStorage()
                    return innerStorage?[key]
                }
            }
            set {
                workingQueue.async(flags: .barrier) {
                    var innerStorage: [Key: Value] = self.innerStorage() ?? [:]
                    innerStorage[key] = newValue
                    self.outerStorage[ObjectIdentifier(Value.self)] = innerStorage
                }
            }
        }

        private func innerStorage<Key, Value>() -> [Key: Value]? where Key: Hashable {
            outerStorage[ObjectIdentifier(Value.self)] as? [Key: Value]
        }
    }
}
