//
//  LegacyMultiWalletMainContentViewSectionsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class LegacyMultiWalletMainContentViewSectionsProvider: MultiWalletMainContentViewSectionsProvider {
    private let userWalletModel: UserWalletModel
    private let optionsEditing: OrganizeTokensOptionsEditing
    private let tokenSectionsAdapter: TokenSectionsAdapter

    private let mappingQueue = DispatchQueue(
        label: "com.tangem.LegacyMultiWalletMainContentViewSectionsProvider.mappingQueue",
        qos: .userInitiated
    )

    private var cachedTokenItemViewModels: [ObjectIdentifier: TokenItemViewModel] = [:]

    private var bag: Set<AnyCancellable> = []

    private weak var itemViewModelFactory: MultiWalletMainContentItemViewModelFactory?

    init(
        userWalletModel: UserWalletModel,
        optionsEditing: OrganizeTokensOptionsEditing,
        tokenSectionsAdapter: TokenSectionsAdapter
    ) {
        self.userWalletModel = userWalletModel
        self.tokenSectionsAdapter = tokenSectionsAdapter
        self.optionsEditing = optionsEditing
    }

    func makePlainSectionsPublisher() -> some Publisher<[MultiWalletMainContentPlainSection], Never> {
        // [REDACTED_TODO_COMMENT]
        let sourcePublisherFactory = TokenSectionsSourcePublisherFactory()

        // from wms and balance, one per acc
        let tokenSectionsSourcePublisher = sourcePublisherFactory
            .makeSourcePublisherForMainScreen(for: userWalletModel)

        // from tokenSectionsSourcePublisher and userTokensManager, one per acc
        let organizedTokensSectionsPublisher = tokenSectionsAdapter
            .organizedSections(from: tokenSectionsSourcePublisher, on: mappingQueue)
            .share(replay: 1)

        // sections with cache, one per acc
        let sectionsPublisher = organizedTokensSectionsPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, sections in
                return viewModel.convertToSections(sections)
            }
            .receiveOnMain()
            .share(replay: 1)

        subscribeToOrganizedTokensSectionsPublisher(with: organizedTokensSectionsPublisher)

        return sectionsPublisher
    }

    func makeAccountSectionsPublisher() -> some Publisher<[MultiWalletMainContentAccountSection], Never> {
        return AnyPublisher.empty
    }

    func setup(with itemViewModelFactory: MultiWalletMainContentItemViewModelFactory) {
        self.itemViewModelFactory = itemViewModelFactory
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

        let sectionItemsFactory = MultiWalletTokenItemsSectionFactory()

        return sections.enumerated().map { index, section in
            let sectionViewModel = sectionItemsFactory.makeSectionViewModel(from: section.model, atIndex: index)
            let itemViewModels = section.items.map { item in
                switch item {
                case .default(let walletModel):
                    // Fetching existing cached View Model for this Wallet Model, if available
                    let cacheKey = ObjectIdentifier(walletModel)
                    if let cachedViewModel = cachedTokenItemViewModels[cacheKey] {
                        return cachedViewModel
                    }
                    let viewModel = itemViewModelFactory.makeTokenItemViewModel(from: item, using: sectionItemsFactory)
                    cachedTokenItemViewModels[cacheKey] = viewModel
                    return viewModel
                case .withoutDerivation:
                    return itemViewModelFactory.makeTokenItemViewModel(from: item, using: sectionItemsFactory)
                }
            }

            return MultiWalletMainContentPlainSection(model: sectionViewModel, items: itemViewModels)
        }
    }

    private func removeOldCachedTokenViewModels(_ sections: [TokenSectionsAdapter.Section]) {
        let cacheKeys = sections
            .flatMap(\.walletModels)
            .map(ObjectIdentifier.init)
            .toSet()

        cachedTokenItemViewModels = cachedTokenItemViewModels.filter { cacheKeys.contains($0.key) }
    }

    private func subscribeToOrganizedTokensSectionsPublisher(with publisher: some Publisher<[TokenSectionsAdapter.Section], Never>) {
        // Clearing previous subscriptions, shouldn't happen but just in case
        bag.removeAll()

        publisher
            .withWeakCaptureOf(self)
            .sink { viewModel, sections in
                viewModel.removeOldCachedTokenViewModels(sections)
            }
            .store(in: &bag)

        publisher
            .map { $0.flatMap(\.items) }
            .removeDuplicates()
            .map { $0.map(\.walletModelId) }
            .withWeakCaptureOf(self)
            .flatMapLatest { provider, walletModelIds in
                return provider.optionsEditing.save(reorderedWalletModelIds: walletModelIds, source: .mainScreen)
            }
            .sink()
            .store(in: &bag)
    }
}

// MARK: - Convenience extensions

private extension TokenSectionsAdapter.Section {
    var walletModels: [any WalletModel] {
        return items.compactMap(\.walletModel)
    }
}
