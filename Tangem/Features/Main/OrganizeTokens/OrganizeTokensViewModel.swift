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
import TangemUI
import TangemFoundation

// [REDACTED_TODO_COMMENT]
struct _IndexPath: Hashable {
    let outerSection: Int
    let innerSection: Int
    // [REDACTED_TODO_COMMENT]
    let _item: Int

    // [REDACTED_TODO_COMMENT]
    init(outerSection: Int, innerSection: Int, item: Int) {
        self.outerSection = outerSection
        self.innerSection = innerSection
        _item = item
    }
}

final class OrganizeTokensViewModel: ObservableObject, Identifiable {
    /// Sentinel value for `item` of `IndexPath` representing a section.
    var sectionHeaderItemIndex: Int { .min }

    private(set) lazy var headerViewModel = OrganizeTokensHeaderViewModel(
        optionsProviding: optionsProviding,
        optionsEditing: optionsEditing
    )

    @Published private(set) var __sections: [_OrganizeTokensListSection] = []
    @available(*, deprecated, message: "Delete")
    @Published private(set) var sections: [OrganizeTokensListSection] = []

    let id = UUID()

    private weak var coordinator: OrganizeTokensRoutable?

    private let userWalletModel: UserWalletModel
    private let tokenSectionsAdapter: TokenSectionsAdapter
    private let optionsProviding: OrganizeTokensOptionsProviding
    private let optionsEditing: OrganizeTokensOptionsEditing

    private let _dragAndDropActionsCache = OrganizeTokensDragAndDropActionsAggregatedCache()
    private var currentlyDraggedSectionIdentifier: AnyHashable?
    private var currentlyDraggedSectionItems: [OrganizeTokensListItemViewModel] = []

    private let onSave = PassthroughSubject<Void, Never>()

    private let mappingQueue = DispatchQueue(
        label: "com.tangem.OrganizeTokensViewModel.mappingQueue",
        qos: .userInitiated
    )

    private var bag: Set<AnyCancellable> = []
    private var didBind = false

    init(
        coordinator: OrganizeTokensRoutable,
        userWalletModel: UserWalletModel,
        tokenSectionsAdapter: TokenSectionsAdapter,
        optionsProviding: OrganizeTokensOptionsProviding,
        optionsEditing: OrganizeTokensOptionsEditing
    ) {
        self.coordinator = coordinator
        self.userWalletModel = userWalletModel
        self.tokenSectionsAdapter = tokenSectionsAdapter
        self.optionsProviding = optionsProviding
        self.optionsEditing = optionsEditing
    }

    func onViewWillAppear() {
        bind()
    }

    func onViewAppear() {
        reportScreenOpened()
    }

    func onCancelButtonTap() {
        Analytics.log(.organizeTokensButtonCancel)
        coordinator?.didTapCancelButton()
    }

    func onApplyButtonTap() {
        onSave.send()
    }

    private func bind() {
        if didBind { return }

        let sourcePublisherFactory = TokenSectionsSourcePublisherFactory()
        let aggregatedCache = _dragAndDropActionsCache
        var tokenSectionsAdapterCache: [ObjectIdentifier: TokenSectionsAdapter] = [:] // [REDACTED_TODO_COMMENT]

        // [REDACTED_TODO_COMMENT]
        userWalletModel
            .accountModelsManager
            .cryptoAccountModelsPublisher // [REDACTED_TODO_COMMENT]
            .withWeakCaptureOf(self)
            .flatMapLatest { provider, cryptoAccountModels -> AnyPublisher<[_OrganizeTokensListSection], Never> in
                guard cryptoAccountModels.isNotEmpty else {
                    return .just(output: [])
                }

                // [REDACTED_TODO_COMMENT]
                return cryptoAccountModels
                    .enumerated()
                    .map { outerSectionIndex, cryptoAccountModel in
                        let tokenSectionsAdapter = Self
                            ._makeOrGetCachedTokenSectionsAdapter(for: cryptoAccountModel, using: &tokenSectionsAdapterCache)

                        let tokenSectionsSourcePublisher = sourcePublisherFactory
                            .makeSourcePublisher(for: cryptoAccountModel)

                        let organizedTokensSectionsPublisher = tokenSectionsAdapter
                            .organizedSections(from: tokenSectionsSourcePublisher, on: provider.mappingQueue)

                        return organizedTokensSectionsPublisher
                            .map { sections in
                                let accountSectionModel = _AccountModel(
                                    id: cryptoAccountModel.id,
                                    name: cryptoAccountModel.name,
                                    iconData: AccountModelUtils.UI.iconViewData(accountModel: cryptoAccountModel)
                                )
                                return _OrganizeTokensListSection(
                                    model: accountSectionModel,
                                    items: Self.map(
                                        sections: sections,
                                        sortingOption: .dragAndDrop, // [REDACTED_TODO_COMMENT]
                                        groupingOption: .none, // [REDACTED_TODO_COMMENT]
                                        // [REDACTED_TODO_COMMENT]
                                        dragAndDropActionsCache: aggregatedCache.cache(forOuterSectionIndex: outerSectionIndex)
                                    )
                                )
                            }
                    }
                    .combineLatest()
            }
            .assign(to: &$__sections)

        /*
         let sourcePublisherFactory = TokenSectionsSourcePublisherFactory()
         // [REDACTED_TODO_COMMENT]
         let tokenSectionsSourcePublisher = sourcePublisherFactory.makeSourcePublisher(for: userWalletModel)

         let organizedTokensSectionsPublisher = tokenSectionsAdapter
         .organizedSections(from: tokenSectionsSourcePublisher, on: mappingQueue)
         .share(replay: 1)

         let cache = dragAndDropActionsCache

         // Resetting drag-and-drop actions cache for grouped sections
         // when the structure of the underlying model has changed
         organizedTokensSectionsPublisher
         .withLatestFrom(optionsProviding.groupingOption) { ($0, $1) }
         .filter { $0.1.isGrouped }
         .map(\.0)
         .pairwise()
         .sink { cache.resetIfNeeded(sectionsChange: $0, isGroupingEnabled: true) }
         .store(in: &bag)

         // Resetting drag-and-drop actions cache for plain (non-grouped) sections
         // when the structure of the underlying model has changed
         organizedTokensSectionsPublisher
         .withLatestFrom(optionsProviding.groupingOption) { ($0, $1) }
         .filter { !$0.1.isGrouped }
         .map(\.0)
         .pairwise()
         .sink { cache.resetIfNeeded(sectionsChange: $0, isGroupingEnabled: false) }
         .store(in: &bag)

         // Resetting drag-and-drop actions cache unconditionally when sort option is changed
         optionsProviding
         .sortingOption
         .removeDuplicates()
         .sink { _ in cache.reset() }
         .store(in: &bag)

         organizedTokensSectionsPublisher
         .withLatestFrom(
         optionsProviding.sortingOption,
         optionsProviding.groupingOption
         ) { ($0, $1.0, $1.1, cache) }
         .map(Self.map)
         .receive(on: DispatchQueue.main)
         .assign(to: \.sections, on: self, ownership: .weak)
         .store(in: &bag)

         let onSavePublisher = onSave
         .throttle(for: 1.0, scheduler: DispatchQueue.main, latest: false)
         .share(replay: 1)

         onSavePublisher
         .receive(on: mappingQueue)
         .withWeakCaptureOf(self)
         .flatMapLatest { viewModel, _ in
         let walletModelIds = viewModel
         .sections
         .flatMap(\.items)
         .map(\.id.walletModelId)

         return viewModel.optionsEditing.save(reorderedWalletModelIds: walletModelIds, source: .organizeTokens)
         }
         .withWeakCaptureOf(self)
         .receive(on: DispatchQueue.main)
         .sink { viewModel, _ in
         viewModel.coordinator?.didTapSaveButton()
         }
         .store(in: &bag)

         onSavePublisher
         .withLatestFrom(
         optionsProviding.sortingOption,
         optionsProviding.groupingOption
         )
         .withWeakCaptureOf(self)
         .sink { input in
         let (viewModel, (sortingOption, groupingOption)) = input
         viewModel.reportOnSaveButtonTap(sortingOption: sortingOption, groupingOption: groupingOption)
         }
         .store(in: &bag)
         */

        didBind = true
    }

    // [REDACTED_TODO_COMMENT]
    private static func _makeOrGetCachedTokenSectionsAdapter(
        for cryptoAccountModel: any CryptoAccountModel,
        using cache: inout [ObjectIdentifier: TokenSectionsAdapter]
    ) -> TokenSectionsAdapter {
        let cacheKey = ObjectIdentifier(cryptoAccountModel)

        if let cachedAdapter: TokenSectionsAdapter = cache /* .tokenSectionsAdapters */ [cacheKey] {
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
        /* cache.mutate { $0.tokenSectionsAdapters[cacheKey] = tokenSectionsAdapter } */

        return tokenSectionsAdapter
    }

    private static func map(
        sections: [TokenSectionsAdapter.Section],
        sortingOption: UserTokensReorderingOptions.Sorting,
        groupingOption: UserTokensReorderingOptions.Grouping,
        dragAndDropActionsCache: OrganizeTokensDragAndDropActionsCache
    ) -> [OrganizeTokensListSection] {
        let tokenIconInfoBuilder = TokenIconInfoBuilder()
        let listFactory = OrganizeTokensListFactory(tokenIconInfoBuilder: tokenIconInfoBuilder)

        var listItemViewModels = sections.enumerated().map { index, section in
            let isListSectionGrouped = isListSectionGrouped(section)
            let isDraggable = section.items.count > 1
            let items = section.items.map { item in
                listFactory.makeListItemViewModel(
                    sectionItem: item,
                    isDraggable: isDraggable,
                    inGroupedSection: isListSectionGrouped
                )
            }

            return listFactory.makeListSection(from: section.model, with: items, atIndex: index)
        }

        // By design, cached drag-and-drop actions can only be applied when manual sorting is active
        if !sortingOption.isSorted {
            dragAndDropActionsCache.applyDragAndDropActions(
                to: &listItemViewModels,
                isGroupingEnabled: groupingOption.isGrouped
            )
        }

        return listItemViewModels
    }

    private static func isListSectionGrouped(
        _ section: TokenSectionsAdapter.Section
    ) -> Bool {
        switch section.model {
        case .plain:
            return false
        case .group:
            return true
        }
    }

    private func reportScreenOpened() {
        Analytics.log(.organizeTokensScreenOpened)
    }

    private func reportOnSaveButtonTap(
        sortingOption: UserTokensReorderingOptions.Sorting,
        groupingOption: UserTokensReorderingOptions.Grouping
    ) {
        let sortTypeParameterValue: Analytics.ParameterValue
        switch sortingOption {
        case .dragAndDrop:
            sortTypeParameterValue = .sortTypeManual
        case .byBalance:
            sortTypeParameterValue = .sortTypeByBalance
        }

        let groupTypeParameterValue = Analytics.ParameterValue.toggleState(for: groupingOption.isGrouped)

        Analytics.log(
            .organizeTokensButtonApply,
            params: [
                .groupType: groupTypeParameterValue,
                .sortType: sortTypeParameterValue,
            ]
        )
    }
}

// MARK: - Drag and drop support

extension OrganizeTokensViewModel {
    func indexPath(for identifier: AnyHashable) -> _IndexPath? {
        for (outerSectionIndex, outerSection) in __sections.enumerated() {
            // Outer sections can't be dragged, so we don't check them here
            for (innerSectionIndex, innerSection) in outerSection.items.enumerated() {
                if innerSection.id == identifier {
                    return _IndexPath(outerSection: outerSectionIndex, innerSection: innerSectionIndex, item: sectionHeaderItemIndex)
                }
                for (itemIndex, item) in innerSection.items.enumerated() {
                    if item.id.toAnyHashable() == identifier {
                        return _IndexPath(outerSection: outerSectionIndex, innerSection: innerSectionIndex, item: itemIndex)
                    }
                }
            }
        }

        return nil
    }

    func itemViewModel(for identifier: AnyHashable) -> OrganizeTokensListItemViewModel? {
        return __sections
            .flatMap { $0.items }
            .flatMap { $0.items }
            .first { $0.id.toAnyHashable() == identifier }
    }

    func section(for identifier: AnyHashable) -> OrganizeTokensListSection? {
        return __sections
            .flatMap { $0.items }
            .first { $0.id == identifier }
    }

    func move(from sourceIndexPath: _IndexPath, to destinationIndexPath: _IndexPath) {
        guard sourceIndexPath.outerSection == destinationIndexPath.outerSection else {
            assertionFailure("Can't perform move operation between different outer sections")
            return
        }

        let outerSectionIndex = sourceIndexPath.outerSection // Same value for both source and destination
        let cache = _dragAndDropActionsCache.cache(forOuterSectionIndex: outerSectionIndex)
        let isGroupingEnabled = headerViewModel.isGroupingEnabled

        if sourceIndexPath._item == sectionHeaderItemIndex {
            // Moving of inner sections
            guard sourceIndexPath._item == destinationIndexPath._item else {
                assertionFailure("Can't perform move operation between section and item or vice versa")
                return
            }

            let offsetDiff = sourceIndexPath.innerSection > destinationIndexPath.innerSection ? 0 : 1
            __sections[outerSectionIndex].items.move(
                fromOffsets: IndexSet(integer: sourceIndexPath.innerSection),
                toOffset: destinationIndexPath.innerSection + offsetDiff
            )

            cache.addDragAndDropAction(isGroupingEnabled: isGroupingEnabled) { sectionsToMutate in
                try sectionsToMutate.tryMove(
                    fromOffsets: IndexSet(integer: sourceIndexPath.innerSection),
                    toOffset: destinationIndexPath.innerSection + offsetDiff
                )
            }
        } else {
            // Moving of items
            guard sourceIndexPath.innerSection == destinationIndexPath.innerSection else {
                assertionFailure("Can't perform move operation between section and item or vice versa")
                return
            }

            let offsetDiff = sourceIndexPath._item > destinationIndexPath._item ? 0 : 1
            __sections[outerSectionIndex].items[sourceIndexPath.innerSection].items.move(
                fromOffsets: IndexSet(integer: sourceIndexPath._item),
                toOffset: destinationIndexPath._item + offsetDiff
            )

            cache.addDragAndDropAction(isGroupingEnabled: isGroupingEnabled) { sectionsToMutate in
                guard sectionsToMutate.indices.contains(sourceIndexPath.innerSection) else {
                    throw Error.sectionOffsetOutOfBound(
                        offset: sourceIndexPath.innerSection,
                        count: sectionsToMutate.count,
                    )
                }

                try sectionsToMutate[sourceIndexPath.innerSection].items.tryMove(
                    fromOffsets: IndexSet(integer: sourceIndexPath._item),
                    toOffset: destinationIndexPath._item + offsetDiff
                )
            }
        }
    }

    func onDragStart(at indexPath: _IndexPath) {
        // A started drag-and-drop session always disables sorting by balance
        optionsEditing.sort(by: .dragAndDrop)

        // Process further only if a section is currently being dragged
        guard indexPath._item == sectionHeaderItemIndex else {
            return
        }

        // Setting the sort option to `dragAndDrop` will cause an update of SwiftUI view identifiers for all
        // cells and sections in `OrganizeTokensView`. This update may take a couple render passes, therefore
        // we must wait for this update to finish before collapsing the dragged section
        // (by calling `beginDragAndDropSession(forSectionWithIdentifier:)`), otherwise UI glitches may appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.beginDragAndDropSession(forSectionAtIndexPath: indexPath)
        }
    }

    func onDragAnimationCompletion() {
        endDragAndDropSessionForCurrentlyDraggedSectionIfNeeded()
    }

    private func beginDragAndDropSession(forSectionAtIndexPath indexPath: _IndexPath) {
        assert(
            currentlyDraggedSectionIdentifier == nil,
            "Attempting to start a new drag and drop session without finishing the previous one"
        )

        currentlyDraggedSectionIdentifier = __sections[indexPath.outerSection].items[indexPath.innerSection].id
        currentlyDraggedSectionItems = __sections[indexPath.outerSection].items[indexPath.innerSection].items
        __sections[indexPath.outerSection].items[indexPath.innerSection].items.removeAll()
    }

    private func endDragAndDropSession(forSectionWithIdentifier identifier: AnyHashable) {
        guard let indexPath = indexPath(for: identifier) else {
            return
        }

        __sections[indexPath.outerSection].items[indexPath.innerSection].items = currentlyDraggedSectionItems
        currentlyDraggedSectionItems.removeAll()
    }

    private func endDragAndDropSessionForCurrentlyDraggedSectionIfNeeded() {
        currentlyDraggedSectionIdentifier.map(endDragAndDropSession(forSectionWithIdentifier:))
        currentlyDraggedSectionIdentifier = nil
    }

    private func itemViewModel(at indexPath: _IndexPath) -> OrganizeTokensListItemViewModel {
        return __sections[indexPath.outerSection]
            .items[indexPath.innerSection]
            .items[indexPath._item]
    }

    private func section(at indexPath: _IndexPath) -> OrganizeTokensListSection? {
        guard indexPath._item == sectionHeaderItemIndex else {
            return nil
        }

        return __sections[indexPath.outerSection]
            .items[indexPath.innerSection]
    }
}

// MARK: - OrganizeTokensDragAndDropControllerDataSource protocol conformance

extension OrganizeTokensViewModel: OrganizeTokensDragAndDropControllerDataSource {
    func controller(
        _ controller: OrganizeTokensDragAndDropController,
        numberOfInnerSectionsInOuterSection outerSection: Int
    ) -> Int {
        return __sections[outerSection].items.count
    }

    func controller(
        _ controller: OrganizeTokensDragAndDropController,
        numberOfRowsInInnerSection innerSection: Int,
        outerSection: Int
    ) -> Int {
        return __sections[outerSection].items[innerSection].items.count
    }

    func controller(
        _ controller: OrganizeTokensDragAndDropController,
        listViewKindForItemAt indexPath: _IndexPath
    ) -> OrganizeTokensDragAndDropControllerListViewKind {
        return indexPath._item == sectionHeaderItemIndex ? .sectionHeader : .cell
    }

    func controller(
        _ controller: OrganizeTokensDragAndDropController,
        listViewIdentifierForItemAt indexPath: _IndexPath
    ) -> AnyHashable {
        return section(at: indexPath)?.id ?? itemViewModel(at: indexPath).id.toAnyHashable()
    }
}

// MARK: - Auxiliary types

extension OrganizeTokensViewModel {
    enum Error: Swift.Error {
        case sectionOffsetOutOfBound(offset: Int, count: Int)
    }
}
