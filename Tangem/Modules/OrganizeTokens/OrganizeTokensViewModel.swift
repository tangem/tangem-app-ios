//
//  OrganizeTokensViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import struct BlockchainSdk.Token

final class OrganizeTokensViewModel: ObservableObject {
    private typealias Token = BlockchainSdk.Token

    /// Sentinel value for `item` of `IndexPath` representing a section.
    var sectionHeaderItemIndex: Int { .min }

    private(set) lazy var headerViewModel = OrganizeTokensHeaderViewModel()

    @Published var sections: [OrganizeTokensListSectionViewModel] = []

    private unowned let coordinator: OrganizeTokensRoutable

    private let userWalletModel: UserWalletModel
    private var userTokenListManager: UserTokenListManager { userWalletModel.userTokenListManager }

    private var currentlyDraggedSectionIdentifier: UUID?
    private var currentlyDraggedSectionItems: [OrganizeTokensListItemViewModel] = []

    private var didPerformBind = false

    private var bag = Set<AnyCancellable>()

    init(
        coordinator: OrganizeTokensRoutable,
        userWalletModel: UserWalletModel
    ) {
        self.coordinator = coordinator
        self.userWalletModel = userWalletModel
    }

    func onViewAppear() {
        bindIfNeeded()
    }

    func onViewDisappear() {
        // [REDACTED_TODO_COMMENT]
    }

    func onCancelButtonTap() {
        coordinator.didTapCancelButton()
    }

    func onApplyButtonTap() {
        // [REDACTED_TODO_COMMENT]
    }

    private func bindIfNeeded() {
        if didPerformBind {
            return
        }

        // [REDACTED_TODO_COMMENT]
        // [REDACTED_TODO_COMMENT]
        userWalletModel
            .subscribeToWalletModels()
            .map(Self.map)
            .weakAssign(to: \.sections, on: self)
            .store(in: &bag)

        didPerformBind = true
    }

    private static func map(
        _ walletModels: [WalletModel]
    ) -> [OrganizeTokensListSectionViewModel] {
        return walletModels.map { walletModel in
            let blockchainNetwork = walletModel.blockchainNetwork
            let networkItem = map(blockchainNetwork)
            let tokenItems = map(walletModel.getTokens(), in: blockchainNetwork)
            // [REDACTED_TODO_COMMENT]
            return OrganizeTokensListSectionViewModel(
                style: .fixed(title: Localization.walletNetworkGroupTitle(blockchainNetwork.blockchain.displayName)),
                items: [networkItem] + tokenItems
            )
        }
    }

    private static func map(
        _ blockchainNetwork: BlockchainNetwork
    ) -> OrganizeTokensListItemViewModel {
        let tokenIcon = TokenIconInfoBuilder().build(
            for: .coin,
            in: blockchainNetwork.blockchain
        )
        return makeListItemViewModel(tokenIcon: tokenIcon)
    }

    private static func map(
        _ tokens: [Token],
        in blockchainNetwork: BlockchainNetwork
    ) -> [OrganizeTokensListItemViewModel] {
        let tokenIconInfoBuilder = TokenIconInfoBuilder()
        return tokens.map { token in
            let tokenIcon = tokenIconInfoBuilder.build(
                for: .token(value: token),
                in: blockchainNetwork.blockchain
            )
            return makeListItemViewModel(tokenIcon: tokenIcon)
        }
    }

    private static func makeListItemViewModel(
        tokenIcon: TokenIconInfo
    ) -> OrganizeTokensListItemViewModel {
        // [REDACTED_TODO_COMMENT]
        return OrganizeTokensListItemViewModel(
            tokenIcon: tokenIcon,
            balance: .noData,
            isDraggable: false,
            networkUnreachable: false,
            hasPendingTransactions: false
        )
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
