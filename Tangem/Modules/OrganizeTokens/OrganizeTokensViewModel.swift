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

    private var currentlyDraggedSectionIdentifier: UUID?
    private var currentlyDraggedSectionItems: [OrganizeTokensListItemViewModel] = []
    private var itemViewModelsIdentifiers: [AnyHashable: UUID] = [:]

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

        let walletModelsDidChangePublisher = walletModelsPublisher
            .receive(on: mappingQueue)
            .flatMap { walletModels in
                return walletModels
                    .map(\.walletDidChangePublisher)
                    .merge()
            }
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .withLatestFrom(walletModelsPublisher)

        walletModelsAdapter
            .organizedWalletModels(from: walletModelsDidChangePublisher, on: mappingQueue)
            .withLatestFrom(organizeTokensOptionsProviding.sortingOption) { ($0, $1) }
            .withWeakCaptureOf(self)
            .map { input in
                let (viewModel, (sections, option)) = input
                return viewModel.map(walletModelsSections: sections, sortingOption: option)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.sections, on: self, ownership: .weak)
            .store(in: &bag)

        onSave
            .throttle(for: 1.0, scheduler: RunLoop.main, latest: false)
            .eraseToAnyPublisher()
            .withWeakCaptureOf(self)
            .flatMapLatest { viewModel, _ in
                viewModel.organizeTokensOptionsEditing.save()
            }
            .sink()
            .store(in: &bag)
    }

    private func map(
        walletModelsSections: [OrganizeWalletModelsAdapter.Section],
        sortingOption: OrganizeTokensOptions.Sorting
    ) -> [OrganizeTokensListSectionViewModel] {
        let tokenIconInfoBuilder = TokenIconInfoBuilder()
        let isListItemsDraggable = isListItemDraggable(sortingOption: sortingOption)

        return walletModelsSections.enumerated().map { index, section in
            let items = section.items.map { item in
                return map(
                    walletModel: item,
                    isDraggable: isListItemsDraggable,
                    using: tokenIconInfoBuilder
                )
            }
            let viewModelIdentifier = viewModelIdentifier(for: section.model, atIndex: index)

            switch section.model {
            case .group(let blockchainNetwork):
                let title = Localization.walletNetworkGroupTitle(blockchainNetwork.blockchain.displayName)
                return OrganizeTokensListSectionViewModel(
                    id: viewModelIdentifier,
                    style: .draggable(title: title),
                    items: items
                )
            case .plain:
                return OrganizeTokensListSectionViewModel(
                    id: viewModelIdentifier,
                    style: .invisible,
                    items: items
                )
            }
        }
    }

    private func map(
        walletModel: WalletModel,
        isDraggable: Bool,
        using tokenIconInfoBuilder: TokenIconInfoBuilder
    ) -> OrganizeTokensListItemViewModel {
        let tokenIcon = tokenIconInfoBuilder.build(
            for: walletModel.amountType,
            in: walletModel.blockchainNetwork.blockchain
        )
        let viewModelIdentifier = viewModelIdentifier(for: walletModel)

        return OrganizeTokensListItemViewModel(
            id: viewModelIdentifier,
            tokenIcon: tokenIcon,
            balance: fiatBalance(for: walletModel),
            isNetworkUnreachable: walletModel.state.isBlockchainUnreachable,
            isDraggable: isDraggable
        )
    }

    private func fiatBalance(for walletModel: WalletModel) -> LoadableTextView.State {
        guard !walletModel.rateFormatted.isEmpty else { return .noData }

        switch walletModel.state {
        case .created, .idle, .noAccount, .noDerivation:
            return .loaded(text: walletModel.fiatBalance)
        case .loading:
            return .loading
        case .failed:
            return .noData
        }
    }

    private func isListItemDraggable(
        sortingOption: OrganizeTokensOptions.Sorting
    ) -> Bool {
        switch sortingOption {
        case .dragAndDrop:
            return true
        case .byBalance:
            return false
        }
    }

    private func viewModelIdentifier(
        for sectionType: OrganizeWalletModelsAdapter.SectionType,
        atIndex sectionIndex: Int
    ) -> UUID {
        // The identity of sections isn't affected by grouping status, so the constant is used
        let isGroupingEnabled = true
        switch sectionType {
        case .group(let blockchainNetwork):
            let key = IdentifierKey(value: blockchainNetwork, isGroupingEnabled: isGroupingEnabled)
            return viewModelIdentifier(for: key)
        case .plain:
            let key = IdentifierKey(value: sectionIndex, isGroupingEnabled: isGroupingEnabled)
            return viewModelIdentifier(for: key)
        }
    }

    private func viewModelIdentifier(for walletModel: WalletModel) -> UUID {
        let isGroupingEnabled = headerViewModel.isGroupingEnabled
        let key = IdentifierKey(value: walletModel.id, isGroupingEnabled: isGroupingEnabled)
        return viewModelIdentifier(for: key)
    }

    private func viewModelIdentifier<T>(for key: IdentifierKey<T>) -> UUID {
        if let existingIdentifier = itemViewModelsIdentifiers[key] {
            return existingIdentifier
        }

        let newIdentifier = UUID()
        itemViewModelsIdentifiers[key] = newIdentifier

        return newIdentifier
    }
}

// MARK: - Drag and drop support

extension OrganizeTokensViewModel {
    func itemViewModel(for identifier: UUID) -> OrganizeTokensListItemViewModel? {
        return sections
            .flatMap { $0.items }
            .first { $0.id == identifier }
    }

    func sectionViewModel(for identifier: UUID) -> OrganizeTokensListSectionViewModel? {
        return sections
            .first { $0.id == identifier }
    }

    func viewModelIdentifier(at indexPath: IndexPath) -> UUID? {
        return sectionViewModel(at: indexPath)?.id ?? itemViewModel(at: indexPath).id
    }

    func move(from sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath.item == sectionHeaderItemIndex {
            assert(sourceIndexPath.item == destinationIndexPath.item, "Can't perform move operation between section and item or vice versa")
            let diff = sourceIndexPath.section > destinationIndexPath.section ? 0 : 1
            sections.move(
                fromOffsets: IndexSet(integer: sourceIndexPath.section),
                toOffset: destinationIndexPath.section + diff
            )
        } else {
            assert(sourceIndexPath.section == destinationIndexPath.section, "Can't perform move operation between section and item or vice versa")
            let diff = sourceIndexPath.item > destinationIndexPath.item ? 0 : 1
            sections[sourceIndexPath.section].items.move(
                fromOffsets: IndexSet(integer: sourceIndexPath.item),
                toOffset: destinationIndexPath.item + diff
            )
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

    private func beginDragAndDropSession(forSectionWithIdentifier identifier: UUID) {
        guard let index = index(forSectionWithIdentifier: identifier) else { return }

        assert(
            currentlyDraggedSectionIdentifier == nil,
            "Attempting to start a new drag and drop session without finishing the previous one"
        )

        currentlyDraggedSectionIdentifier = identifier
        currentlyDraggedSectionItems = sections[index].items
        sections[index].items.removeAll()
    }

    private func endDragAndDropSession(forSectionWithIdentifier identifier: UUID) {
        guard let index = index(forSectionWithIdentifier: identifier) else { return }

        sections[index].items = currentlyDraggedSectionItems
        currentlyDraggedSectionItems.removeAll()
    }

    private func endDragAndDropSessionForCurrentlyDraggedSectionIfNeeded() {
        currentlyDraggedSectionIdentifier.map(endDragAndDropSession(forSectionWithIdentifier:))
        currentlyDraggedSectionIdentifier = nil
    }

    private func index(forSectionWithIdentifier identifier: UUID) -> Int? {
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

// MARK: - Auxiliary types

private extension OrganizeTokensViewModel {
    /// SE-0283 'Implement Equatable, Comparable, and Hashable conformance for Tuples'
    /// got reverted and the implementation never landed, therefore separate type is used as a key.
    struct IdentifierKey<T>: Hashable where T: Hashable {
        let value: T
        let isGroupingEnabled: Bool
    }
}
