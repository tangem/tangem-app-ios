//
//  AccountsAwareOrganizeTokensViewModel.swift
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
final class AccountsAwareOrganizeTokensViewModel: ObservableObject, Identifiable {
    private typealias EntitiesCache = ThreadSafeContainer<Cache>

    /// Sentinel value for `item` of `IndexPath` representing a section.
    var sectionHeaderItemIndex: Int { .min }

    let id = UUID()

    @Published private(set) var headerViewModel: OrganizeTokensHeaderViewModel?

    @Published private(set) var sections: [OrganizeTokensListOuterSection] = []

    private weak var coordinator: OrganizeTokensRoutable?

    private let userWalletModel: UserWalletModel
    private var optionsEditing: OrganizeTokensOptionsEditing? // Optional property due to late binding
    private let dragAndDropActionsCache = OrganizeTokensDragAndDropActionsAggregatedCache()
    private var currentlyDraggedSectionIdentifier: AnyHashable?
    private var currentlyDraggedSectionItems: [OrganizeTokensListItemViewModel] = []

    private let onSaveSubject = PassthroughSubject<Void, Never>()

    private let mappingQueue = DispatchQueue(
        label: "com.tangem.AccountsAwareOrganizeTokensViewModel.mappingQueue",
        qos: .userInitiated
    )

    private var bag: Set<AnyCancellable> = []
    private var cryptoAccountModelsBag: Set<AnyCancellable> = []
    private var didBind = false
    private var didBindToCryptoAccountModels = false
    private var didSave = false

    init(
        userWalletModel: UserWalletModel,
        coordinator: OrganizeTokensRoutable
    ) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
    }

    func onViewWillAppear() {
        bind()
    }

    func onViewAppear() {
        logScreenOpened()
    }

    private func bind() {
        ensureOnMainQueue()

        if didBind { return }

        didBind = true

        let sourcePublisherFactory = TokenSectionsSourcePublisherFactory()
        let aggregatedCache = dragAndDropActionsCache
        let entitiesCache = EntitiesCache(.init())

        let onSavePublisher = onSaveSubject
            .throttle(for: 1.0, scheduler: DispatchQueue.main, latest: false)
            .share(replay: 1)

        let cryptoAccountModelsPublisher = userWalletModel
            .accountModelsManager
            .cryptoAccountModelsPublisher
            .share(replay: 1)

        // Shared instance between multiple accounts, optional due to late binding
        var sharedOptionsManagerAdapter: AccountsOrganizeOptionsManagerAdapter? = nil

        cryptoAccountModelsPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { viewModel, cryptoAccountModels -> AnyPublisher<[OrganizeTokensListOuterSection], Never> in
                viewModel.cryptoAccountModelsBag.removeAll() // Invalidate all old subscriptions since the list of accounts may change
                viewModel.didBindToCryptoAccountModels = false // Allow re-binding of options manager for new set of accounts
                sharedOptionsManagerAdapter = nil // Clear old options manager reference

                guard cryptoAccountModels.isNotEmpty else {
                    return .just(output: [])
                }

                let shouldUseInvisibleOuterSection = cryptoAccountModels.count == 1

                let outerSectionViewModels = cryptoAccountModels.map { cryptoAccountModel in
                    return OrganizeTokensListOuterSectionViewModel(
                        cryptoAccountModel: cryptoAccountModel,
                        shouldUseInvisibleOuterSection: shouldUseInvisibleOuterSection
                    )
                }

                viewModel.dragAndDropActionsCache.purgeCache(using: outerSectionViewModels)

                return cryptoAccountModels
                    .enumerated()
                    .map { outerSectionIndex, cryptoAccountModel in
                        let outerSectionViewModel = outerSectionViewModels[outerSectionIndex]
                        let dragAndDropActionsCache = aggregatedCache.dragAndDropActionsCache(for: outerSectionViewModel)

                        let optionsManagerAdapter: AccountsOrganizeOptionsManagerAdapter
                        if let adapter = sharedOptionsManagerAdapter {
                            optionsManagerAdapter = adapter
                        } else {
                            // Currently, all crypto accounts share the same group/sort options, so we create a single,
                            // shared instance of the `AccountsOrganizeOptionsManagerAdapter` adapter here
                            let userTokensReorderer = cryptoAccountModel.userTokensManager
                            optionsManagerAdapter = AccountsOrganizeOptionsManagerAdapter(userTokensReorderer: userTokensReorderer)
                            sharedOptionsManagerAdapter = optionsManagerAdapter
                        }

                        let tokenSectionsAdapter = Self
                            .makeOrGetCachedTokenSectionsAdapter(
                                for: cryptoAccountModel,
                                optionsProviding: optionsManagerAdapter,
                                using: entitiesCache
                            )

                        let tokenSectionsSourcePublisher = sourcePublisherFactory
                            .makeSourcePublisher(for: cryptoAccountModel, in: viewModel.userWalletModel)

                        let organizedTokensSectionsPublisher = tokenSectionsAdapter
                            .organizedSections(from: tokenSectionsSourcePublisher, on: viewModel.mappingQueue)
                            .share(replay: 1)

                        viewModel.subscribeToCryptoAccountModelsPublisherIfNeeded(
                            cryptoAccountModelsPublisher: cryptoAccountModelsPublisher,
                            onSavePublisher: onSavePublisher,
                            optionsManager: optionsManagerAdapter,
                            entitiesCache: entitiesCache
                        )

                        viewModel.subscribeToOrganizedTokensSectionsPublisher(
                            tokenSectionsPublisher: organizedTokensSectionsPublisher,
                            onSavePublisher: onSavePublisher,
                            optionsManagerAdapter: optionsManagerAdapter,
                            dragAndDropActionsCache: dragAndDropActionsCache,
                            cryptoAccountModel: cryptoAccountModel,
                            outerSectionIndex: outerSectionIndex
                        )

                        return organizedTokensSectionsPublisher
                            .withLatestFrom(
                                optionsManagerAdapter.sortingOptionPublisher,
                                optionsManagerAdapter.groupingOptionPublisher
                            ) { ($0, $1.0, $1.1, dragAndDropActionsCache) }
                            .map(Self.map)
                            .map { OrganizeTokensListOuterSection(model: outerSectionViewModel, items: $0) }
                    }
                    .combineLatest()
            }
            .prefix(untilOutputFrom: onSavePublisher) // Prevents loop caused by updates emitted by `cryptoAccountModelsPublisher` after save
            .receiveOnMain()
            .assign(to: &$sections)
    }

    private func onSave() {
        ensureOnMainQueue()

        if didSave { return }

        didSave = true
        coordinator?.didTapSaveButton()
    }

    private static func makeOrGetCachedTokenSectionsAdapter(
        for cryptoAccountModel: any CryptoAccountModel,
        optionsProviding: OrganizeTokensOptionsProviding,
        using cache: EntitiesCache
    ) -> TokenSectionsAdapter {
        let cacheKey = ObjectIdentifier(cryptoAccountModel)

        if let cachedAdapter = cache.tokenSectionsAdapters[cacheKey] {
            return cachedAdapter
        }

        let userTokensManager = cryptoAccountModel.userTokensManager
        let tokenSectionsAdapter = TokenSectionsAdapter(
            userTokensManager: userTokensManager,
            optionsProviding: optionsProviding,
            preservesLastSortedOrderOnSwitchToDragAndDrop: false
        )
        cache.mutate { $0.tokenSectionsAdapters[cacheKey] = tokenSectionsAdapter }

        return tokenSectionsAdapter
    }

    private static func map(
        sections: [TokenSectionsAdapter.Section],
        sortingOption: UserTokensReorderingOptions.Sorting,
        groupingOption: UserTokensReorderingOptions.Grouping,
        dragAndDropActionsCache: OrganizeTokensDragAndDropActionsCache
    ) -> [OrganizeTokensListInnerSection] {
        let tokenIconInfoBuilder = TokenIconInfoBuilder()
        let listFactory = OrganizeTokensListFactory(tokenIconInfoBuilder: tokenIconInfoBuilder)

        var listItemViewModels = sections.enumerated().map { index, section in
            let isListSectionGrouped = section.isGrouped
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

    /// - Note: This method creates subscriptions for the ENTIRE SET of multiple accounts,
    /// i.e., multiple accounts - one set of these subscriptions.
    private func subscribeToCryptoAccountModelsPublisherIfNeeded(
        cryptoAccountModelsPublisher: some Publisher<[any CryptoAccountModel], Never>,
        onSavePublisher: some Publisher<Void, Never>,
        optionsManager: OrganizeTokensOptionsProviding & OrganizeTokensOptionsEditing,
        entitiesCache: EntitiesCache
    ) {
        if didBindToCryptoAccountModels { return }

        didBindToCryptoAccountModels = true
        optionsEditing = optionsManager

        // Resetting drag-and-drop actions cache unconditionally when sort option is changed
        optionsManager
            .sortingOptionPublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.dragAndDropActionsCache.reset()
            }
            .store(in: &bag)

        // Purge cached entities related to removed accounts when the list of accounts changes
        cryptoAccountModelsPublisher
            .sink { cryptoAccountModels in
                entitiesCache.mutate { $0.purge(using: cryptoAccountModels) }
            }
            .store(in: &bag)

        // Analytics logging on Save button tap
        onSavePublisher
            .withLatestFrom(
                optionsManager.sortingOptionPublisher,
                optionsManager.groupingOptionPublisher
            )
            .withWeakCaptureOf(self)
            .sink { input in
                let (viewModel, (sortingOption, groupingOption)) = input
                viewModel.logOnSaveButtonTap(sortingOption: sortingOption, groupingOption: groupingOption)
            }
            .store(in: &bag)

        setupHeaderViewModel(optionsProviding: optionsManager, optionsEditing: optionsManager)
    }

    /// - Note: This method creates subscriptions for ONE SPECIFIC account,
    /// i.e., for multiple accounts - multiple sets of these subscriptions.
    private func subscribeToOrganizedTokensSectionsPublisher(
        tokenSectionsPublisher: some Publisher<[TokenSectionsAdapter.Section], Never>,
        onSavePublisher: some Publisher<Void, Never>,
        optionsManagerAdapter: AccountsOrganizeOptionsManagerAdapter,
        dragAndDropActionsCache: OrganizeTokensDragAndDropActionsCache,
        cryptoAccountModel: any CryptoAccountModel,
        outerSectionIndex: Int
    ) {
        // Resetting drag-and-drop actions cache for grouped sections
        // when the structure of the underlying model has changed
        tokenSectionsPublisher
            .withLatestFrom(optionsManagerAdapter.groupingOptionPublisher) { ($0, $1) }
            .filter { $0.1.isGrouped }
            .map(\.0)
            .pairwise()
            .sink { dragAndDropActionsCache.resetIfNeeded(sectionsChange: $0, isGroupingEnabled: true) }
            .store(in: &cryptoAccountModelsBag)

        // Resetting drag-and-drop actions cache for plain (non-grouped) sections
        // when the structure of the underlying model has changed
        tokenSectionsPublisher
            .withLatestFrom(optionsManagerAdapter.groupingOptionPublisher) { ($0, $1) }
            .filter { !$0.1.isGrouped }
            .map(\.0)
            .pairwise()
            .sink { dragAndDropActionsCache.resetIfNeeded(sectionsChange: $0, isGroupingEnabled: false) }
            .store(in: &cryptoAccountModelsBag)

        // Saving reordered wallet model IDs on Save button tap and then notifying coordinator
        onSavePublisher
            .withWeakCaptureOf(self)
            .receive(on: mappingQueue)
            .flatMapLatest { viewModel, _ in
                let walletModelIds = viewModel
                    .sections[outerSectionIndex]
                    .items
                    .flatMap(\.items)
                    .map(\.id.walletModelId)

                return optionsManagerAdapter
                    .optionsEditorForReorder(for: cryptoAccountModel)
                    .save(reorderedWalletModelIds: walletModelIds, source: .organizeTokens)
            }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.onSave()
                withExtendedLifetime(optionsManagerAdapter) {}
            }
            .store(in: &cryptoAccountModelsBag)
    }

    private func setupHeaderViewModel(
        optionsProviding: OrganizeTokensOptionsProviding,
        optionsEditing: OrganizeTokensOptionsEditing
    ) {
        // This async call mitigates 'Publishing changes from within view updates is not allowed,
        // this will cause undefined behavior' SwiftUI warning
        DispatchQueue.main.async {
            self.headerViewModel = OrganizeTokensHeaderViewModel(
                optionsProviding: optionsProviding,
                optionsEditing: optionsEditing
            )
        }
    }

    private func logScreenOpened() {
        Analytics.log(.organizeTokensScreenOpened)
    }

    private func logOnSaveButtonTap(
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

extension AccountsAwareOrganizeTokensViewModel {
    func indexPath(for identifier: AnyHashable) -> OrganizeTokensIndexPath? {
        for (outerSectionIndex, outerSection) in sections.enumerated() {
            // Outer sections can't be dragged, so we don't check them here
            for (innerSectionIndex, innerSection) in outerSection.items.enumerated() {
                if innerSection.id == identifier {
                    return OrganizeTokensIndexPath(outerSection: outerSectionIndex, innerSection: innerSectionIndex, item: sectionHeaderItemIndex)
                }
                for (itemIndex, item) in innerSection.items.enumerated() {
                    if item.id.toAnyHashable() == identifier {
                        return OrganizeTokensIndexPath(outerSection: outerSectionIndex, innerSection: innerSectionIndex, item: itemIndex)
                    }
                }
            }
        }

        return nil
    }

    func itemViewModel(for identifier: AnyHashable) -> OrganizeTokensListItemViewModel? {
        return sections
            .flatMap { $0.items }
            .flatMap { $0.items }
            .first { $0.id.toAnyHashable() == identifier }
    }

    func section(for identifier: AnyHashable) -> OrganizeTokensListInnerSection? {
        return sections
            .flatMap { $0.items }
            .first { $0.id == identifier }
    }

    func move(from sourceIndexPath: OrganizeTokensIndexPath, to destinationIndexPath: OrganizeTokensIndexPath) {
        guard sourceIndexPath.outerSection == destinationIndexPath.outerSection else {
            assertionFailure("Can't perform move operation between different outer sections")
            return
        }

        let outerSectionIndex = sourceIndexPath.outerSection // Same value for both source and destination
        let cache = dragAndDropActionsCache.dragAndDropActionsCache(for: sections[outerSectionIndex].model)
        let isGroupingEnabled = headerViewModel?.isGroupingEnabled ?? false

        if sourceIndexPath.item == sectionHeaderItemIndex {
            // Moving of inner sections
            guard sourceIndexPath.item == destinationIndexPath.item else {
                assertionFailure("Can't perform move operation between section and item or vice versa")
                return
            }

            let offsetDiff = sourceIndexPath.innerSection > destinationIndexPath.innerSection ? 0 : 1
            sections[outerSectionIndex].items.move(
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

            let offsetDiff = sourceIndexPath.item > destinationIndexPath.item ? 0 : 1
            sections[outerSectionIndex].items[sourceIndexPath.innerSection].items.move(
                fromOffsets: IndexSet(integer: sourceIndexPath.item),
                toOffset: destinationIndexPath.item + offsetDiff
            )

            cache.addDragAndDropAction(isGroupingEnabled: isGroupingEnabled) { sectionsToMutate in
                guard sectionsToMutate.indices.contains(sourceIndexPath.innerSection) else {
                    throw Error.sectionOffsetOutOfBound(
                        offset: sourceIndexPath.innerSection,
                        count: sectionsToMutate.count,
                    )
                }

                try sectionsToMutate[sourceIndexPath.innerSection].items.tryMove(
                    fromOffsets: IndexSet(integer: sourceIndexPath.item),
                    toOffset: destinationIndexPath.item + offsetDiff
                )
            }
        }
    }

    func onDragStart(at indexPath: OrganizeTokensIndexPath) {
        // A started drag-and-drop session always disables sorting by balance
        optionsEditing?.sort(by: .dragAndDrop)

        // Process further only if a section is currently being dragged
        guard indexPath.item == sectionHeaderItemIndex else {
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

    private func beginDragAndDropSession(forSectionAtIndexPath indexPath: OrganizeTokensIndexPath) {
        assert(
            currentlyDraggedSectionIdentifier == nil,
            "Attempting to start a new drag and drop session without finishing the previous one"
        )

        currentlyDraggedSectionIdentifier = sections[indexPath.outerSection].items[indexPath.innerSection].id
        currentlyDraggedSectionItems = sections[indexPath.outerSection].items[indexPath.innerSection].items
        sections[indexPath.outerSection].items[indexPath.innerSection].items.removeAll()
    }

    private func endDragAndDropSession(forSectionWithIdentifier identifier: AnyHashable) {
        guard let indexPath = indexPath(for: identifier) else {
            return
        }

        sections[indexPath.outerSection].items[indexPath.innerSection].items = currentlyDraggedSectionItems
        currentlyDraggedSectionItems.removeAll()
    }

    private func endDragAndDropSessionForCurrentlyDraggedSectionIfNeeded() {
        currentlyDraggedSectionIdentifier.map(endDragAndDropSession(forSectionWithIdentifier:))
        currentlyDraggedSectionIdentifier = nil
    }

    private func itemViewModel(at indexPath: OrganizeTokensIndexPath) -> OrganizeTokensListItemViewModel {
        return sections[indexPath.outerSection]
            .items[indexPath.innerSection]
            .items[indexPath.item]
    }

    private func section(at indexPath: OrganizeTokensIndexPath) -> OrganizeTokensListInnerSection? {
        guard indexPath.item == sectionHeaderItemIndex else {
            return nil
        }

        return sections[indexPath.outerSection]
            .items[indexPath.innerSection]
    }
}

// MARK: - AccountsAwareOrganizeTokensDragAndDropControllerDataSource protocol conformance

extension AccountsAwareOrganizeTokensViewModel: AccountsAwareOrganizeTokensDragAndDropControllerDataSource {
    func controller(
        _ controller: AccountsAwareOrganizeTokensDragAndDropController,
        numberOfInnerSectionsInOuterSection outerSection: Int
    ) -> Int {
        return sections[outerSection].items.count
    }

    func controller(
        _ controller: AccountsAwareOrganizeTokensDragAndDropController,
        numberOfRowsInInnerSection innerSection: Int,
        andOuterSection outerSection: Int
    ) -> Int {
        return sections[outerSection].items[innerSection].items.count
    }

    func controller(
        _ controller: AccountsAwareOrganizeTokensDragAndDropController,
        listViewKindForItemAt indexPath: OrganizeTokensIndexPath
    ) -> OrganizeTokensDragAndDropControllerListViewKind {
        return indexPath.item == sectionHeaderItemIndex ? .sectionHeader : .cell
    }

    func controller(
        _ controller: AccountsAwareOrganizeTokensDragAndDropController,
        listViewIdentifierForItemAt indexPath: OrganizeTokensIndexPath
    ) -> AnyHashable {
        return section(at: indexPath)?.id ?? itemViewModel(at: indexPath).id.toAnyHashable()
    }
}

// MARK: - OrganizeTokensListFooterActionsHandler protocol conformance

extension AccountsAwareOrganizeTokensViewModel: OrganizeTokensListFooterActionsHandler {
    func onCancelButtonTap() {
        Analytics.log(.organizeTokensButtonCancel)
        coordinator?.didTapCancelButton()
    }

    func onApplyButtonTap() {
        onSaveSubject.send()
    }
}

// MARK: - Auxiliary types

extension AccountsAwareOrganizeTokensViewModel {
    enum Error: Swift.Error {
        case sectionOffsetOutOfBound(offset: Int, count: Int)
    }

    /// A cache for various inner types used in `AccountsAwareOrganizeTokensViewModel`.
    final class Cache {
        /// Keyed by `ObjectIdentifier` of `CryptoAccountModel`.
        var tokenSectionsAdapters: [ObjectIdentifier: TokenSectionsAdapter] = [:]

        func purge(using cryptoAccountModels: [any CryptoAccountModel]) {
            let cacheKeys = cryptoAccountModels
                .map(ObjectIdentifier.init)
                .toSet()

            tokenSectionsAdapters.removeAll { !cacheKeys.contains($0.key) }
        }
    }
}
