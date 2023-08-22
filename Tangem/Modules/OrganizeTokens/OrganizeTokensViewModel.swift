//
//  OrganizeTokensViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import SwiftUI

final class OrganizeTokensViewModel: ObservableObject, Identifiable {
    /// Sentinel value for `item` of `IndexPath` representing a section.
    var sectionHeaderItemIndex: Int { .min }

    private(set) lazy var headerViewModel = OrganizeTokensHeaderViewModel(
        organizeTokensOptionsProviding: organizeTokensOptionsProviding,
        organizeTokensOptionsEditing: organizeTokensOptionsEditing
    )

    @Published private(set) var sections: [OrganizeTokensListSectionViewModel] = []

    let id = UUID()

    private unowned let coordinator: OrganizeTokensRoutable

    private let walletModelsManager: WalletModelsManager
    private let walletModelsAdapter: OrganizeWalletModelsAdapter
    private let organizeTokensOptionsProviding: OrganizeTokensOptionsProviding
    private let organizeTokensOptionsEditing: OrganizeTokensOptionsEditing

    private let dragAndDropActionsCache = OrganizeTokensDragAndDropActionsCache()
    private var currentlyDraggedSectionIdentifier: AnyHashable?
    private var currentlyDraggedSectionItems: [OrganizeTokensListItemViewModel] = []

    private let onSave = PassthroughSubject<Void, Never>()

    private let mappingQueue = DispatchQueue(
        label: "com.tangem.OrganizeTokensViewModel.mappingQueue",
        qos: .userInitiated
    )

    private var bag: Set<AnyCancellable> = []

    init(
        coordinator: OrganizeTokensRoutable,
        walletModelsManager: WalletModelsManager,
        walletModelsAdapter: OrganizeWalletModelsAdapter,
        organizeTokensOptionsProviding: OrganizeTokensOptionsProviding,
        organizeTokensOptionsEditing: OrganizeTokensOptionsEditing
    ) {
        self.coordinator = coordinator
        self.walletModelsManager = walletModelsManager
        self.walletModelsAdapter = walletModelsAdapter
        self.organizeTokensOptionsProviding = organizeTokensOptionsProviding
        self.organizeTokensOptionsEditing = organizeTokensOptionsEditing
    }

    func onViewAppear() {
        bind()
    }

    func onCancelButtonTap() {
        coordinator.didTapCancelButton()
    }

    func onApplyButtonTap() {
        onSave.send()
    }

    private func bind() {
        let walletModelsPublisher = walletModelsManager
            .walletModelsPublisher
            .share(replay: 1)
            .eraseToAnyPublisher()

        let walletModelsDidChangePublisher = walletModelsPublisher
            .receive(on: mappingQueue)
            .flatMap { walletModels in
                return walletModels
                    .map(\.walletDidChangePublisher)
                    .merge()
            }
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .withLatestFrom(walletModelsPublisher)
            .eraseToAnyPublisher()

        let aggregatedWalletModelsPublisher = [
            walletModelsPublisher,
            walletModelsDidChangePublisher,
        ].merge()

        let organizedWalletModelsPublisher = walletModelsAdapter
            .organizedWalletModels(from: aggregatedWalletModelsPublisher, on: mappingQueue)
            .share(replay: 1)

        let cache = dragAndDropActionsCache

        // Resetting drag-and-drop actions cache for grouped sections
        organizedWalletModelsPublisher
            .withLatestFrom(organizeTokensOptionsProviding.groupingOption) { ($0, $1) }
            .filter { $0.1.isGrouped }
            .map(\.0)
            .pairwise()
            .sink { cache.resetIfNeeded(sectionsChange: $0, isGroupingEnabled: true) }
            .store(in: &bag)

        // Resetting drag-and-drop actions cache for plain (non-grouped) sections
        organizedWalletModelsPublisher
            .withLatestFrom(organizeTokensOptionsProviding.groupingOption) { ($0, $1) }
            .filter { !$0.1.isGrouped }
            .map(\.0)
            .pairwise()
            .sink { cache.resetIfNeeded(sectionsChange: $0, isGroupingEnabled: false) }
            .store(in: &bag)

        organizedWalletModelsPublisher
            .withLatestFrom(
                organizeTokensOptionsProviding.sortingOption,
                organizeTokensOptionsProviding.groupingOption
            ) { ($0, $1.0, $1.1, cache) }
            .map(Self.map)
            .receive(on: DispatchQueue.main)
            .assign(to: \.sections, on: self, ownership: .weak)
            .store(in: &bag)

        onSave
            .throttle(for: 1.0, scheduler: RunLoop.main, latest: false)
            .receive(on: mappingQueue)
            .withWeakCaptureOf(self)
            .flatMapLatest { viewModel, _ in
                let walletModelIds = viewModel
                    .sections
                    .flatMap(\.items)
                    .map(\.id.walletModelId)

                return viewModel.organizeTokensOptionsEditing.save(walletModelIds: walletModelIds)
            }
            .sink()
            .store(in: &bag)
    }

    private static func map(
        sections: [OrganizeWalletModelsAdapter.Section],
        sortingOption: OrganizeTokensOptions.Sorting,
        groupingOption: OrganizeTokensOptions.Grouping,
        dragAndDropActionsCache: OrganizeTokensDragAndDropActionsCache
    ) -> [OrganizeTokensListSectionViewModel] {
        let tokenIconInfoBuilder = TokenIconInfoBuilder()
        let listItemViewModelFactory = OrganizeTokensListItemViewModelFactory(tokenIconInfoBuilder: tokenIconInfoBuilder)
        let isListItemsDraggable = isListItemDraggable(sortingOption: sortingOption)

        // Plain sections use section indices (using `enumerated()`) as a stable identity, but in
        // reality we always have only one single plain section, so the identity doesn't matter here
        var listItemViewModels = sections.enumerated().map { index, section in
            let isListSectionGrouped = isListSectionGrouped(section)
            let items = section.items.map { item in
                listItemViewModelFactory.makeListItemViewModel(
                    sectionItem: item,
                    isDraggable: isListItemsDraggable,
                    inGroupedSection: isListSectionGrouped
                )
            }

            switch section.model {
            case .group(let blockchainNetwork):
                let title = Localization.walletNetworkGroupTitle(blockchainNetwork.blockchain.displayName)
                return OrganizeTokensListSectionViewModel(
                    id: blockchainNetwork,
                    style: .draggable(title: title),
                    items: items
                )
            case .plain:
                return OrganizeTokensListSectionViewModel(
                    id: index,
                    style: .invisible,
                    items: items
                )
            }
        }

        // By design, drag-and-drop actions can only be applied when manual sorting is active
        if !sortingOption.isSorted {
            dragAndDropActionsCache.applyDragAndDropActions(
                to: &listItemViewModels,
                isGroupingEnabled: groupingOption.isGrouped
            )
        }

        return listItemViewModels
    }

    private static func isListItemDraggable(
        sortingOption: OrganizeTokensOptions.Sorting
    ) -> Bool {
        switch sortingOption {
        case .manual:
            return true
        case .byBalance:
            return false
        }
    }

    private static func isListSectionGrouped(
        _ section: OrganizeWalletModelsAdapter.Section
    ) -> Bool {
        switch section.model {
        case .group:
            return true
        case .plain:
            return false
        }
    }
}

// MARK: - Drag and drop support

extension OrganizeTokensViewModel {
    func itemViewModel(for identifier: AnyHashable) -> OrganizeTokensListItemViewModel? {
        return sections
            .flatMap { $0.items }
            .first { $0.id.asAnyHashable == identifier }
    }

    func sectionViewModel(for identifier: AnyHashable) -> OrganizeTokensListSectionViewModel? {
        return sections
            .first { $0.id == identifier }
    }

    func viewModelIdentifier(at indexPath: IndexPath) -> AnyHashable {
        return sectionViewModel(at: indexPath)?.id ?? itemViewModel(at: indexPath).id.asAnyHashable
    }

    func move(from sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let isGroupingEnabled = headerViewModel.isGroupingEnabled

        if sourceIndexPath.item == sectionHeaderItemIndex {
            guard sourceIndexPath.item == destinationIndexPath.item else {
                assertionFailure("Can't perform move operation between section and item or vice versa")
                return
            }

            sections.swapAt(sourceIndexPath.section, destinationIndexPath.section)
            dragAndDropActionsCache.addDragAndDropAction(isGroupingEnabled: isGroupingEnabled) { sectionsToMutate in
                sectionsToMutate.swapAt(sourceIndexPath.section, destinationIndexPath.section)
            }
        } else {
            guard sourceIndexPath.section == destinationIndexPath.section else {
                assertionFailure("Can't perform move operation between section and item or vice versa")
                return
            }

            sections[sourceIndexPath.section].items.swapAt(sourceIndexPath.item, destinationIndexPath.item)
            dragAndDropActionsCache.addDragAndDropAction(isGroupingEnabled: isGroupingEnabled) { sectionsToMutate in
                sectionsToMutate[sourceIndexPath.section].items.swapAt(sourceIndexPath.item, destinationIndexPath.item)
            }
        }
    }

    func canStartDragAndDropSession(at indexPath: IndexPath) -> Bool {
        return sectionViewModel(at: indexPath)?.isDraggable ?? itemViewModel(at: indexPath).isDraggable
    }

    func onDragStart(at indexPath: IndexPath) {
        // Process further only if a section is currently being dragged
        guard indexPath.item == sectionHeaderItemIndex else { return }

        beginDragAndDropSession(forSectionWithIdentifier: sections[indexPath.section].id)
    }

    func onDragAnimationCompletion() {
        endDragAndDropSessionForCurrentlyDraggedSectionIfNeeded()
    }

    private func beginDragAndDropSession(forSectionWithIdentifier identifier: AnyHashable) {
        guard let index = index(forSectionWithIdentifier: identifier) else { return }

        assert(
            currentlyDraggedSectionIdentifier == nil,
            "Attempting to start a new drag and drop session without finishing the previous one"
        )

        currentlyDraggedSectionIdentifier = identifier
        currentlyDraggedSectionItems = sections[index].items
        sections[index].items.removeAll()
    }

    private func endDragAndDropSession(forSectionWithIdentifier identifier: AnyHashable) {
        guard let index = index(forSectionWithIdentifier: identifier) else { return }

        sections[index].items = currentlyDraggedSectionItems
        currentlyDraggedSectionItems.removeAll()
    }

    private func endDragAndDropSessionForCurrentlyDraggedSectionIfNeeded() {
        currentlyDraggedSectionIdentifier.map(endDragAndDropSession(forSectionWithIdentifier:))
        currentlyDraggedSectionIdentifier = nil
    }

    private func index(forSectionWithIdentifier identifier: AnyHashable) -> Int? {
        return sections.firstIndex { $0.id == identifier }
    }

    private func itemViewModel(at indexPath: IndexPath) -> OrganizeTokensListItemViewModel {
        return sections[indexPath.section].items[indexPath.item]
    }

    private func sectionViewModel(at indexPath: IndexPath) -> OrganizeTokensListSectionViewModel? {
        guard indexPath.item == sectionHeaderItemIndex else { return nil }

        return sections[indexPath.section]
    }
}

// MARK: - OrganizeTokensDragAndDropControllerDataSource protocol conformance

extension OrganizeTokensViewModel: OrganizeTokensDragAndDropControllerDataSource {
    func numberOfSections(
        for controller: OrganizeTokensDragAndDropController
    ) -> Int {
        return sections.count
    }

    func controller(
        _ controller: OrganizeTokensDragAndDropController,
        numberOfRowsInSection section: Int
    ) -> Int {
        return sections[section].items.count
    }

    func controller(
        _ controller: OrganizeTokensDragAndDropController,
        listViewKindForItemAt indexPath: IndexPath
    ) -> OrganizeTokensDragAndDropControllerListViewKind {
        return indexPath.item == sectionHeaderItemIndex ? .sectionHeader : .cell
    }

    func controller(
        _ controller: OrganizeTokensDragAndDropController,
        listViewIdentifierForItemAt indexPath: IndexPath
    ) -> AnyHashable {
        return viewModelIdentifier(at: indexPath)
    }
}
