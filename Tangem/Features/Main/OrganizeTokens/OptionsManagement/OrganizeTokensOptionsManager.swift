//
//  OrganizeTokensOptionsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

final class OrganizeTokensOptionsManager {
    private typealias OptionChange<T> = (currentValue: T, newValue: T?)

    private let userTokensReorderer: UserTokensReordering
    private let editedGroupingOption: CurrentValueSubject<UserTokensReorderingOptions.Grouping?, Never>
    private let editedSortingOption: CurrentValueSubject<UserTokensReorderingOptions.Sorting?, Never>

    private var groupingOptionToSave: AnyPublisher<OptionChange<UserTokensReorderingOptions.Grouping>, Never> {
        return editedGroupingOption
            .prepend(nil)
            .withLatestFrom(userTokensReorderer.groupingOptionPublisher) { (currentValue: $1, newValue: $0) }
            .eraseToAnyPublisher()
    }

    private var sortingOptionToSave: AnyPublisher<OptionChange<UserTokensReorderingOptions.Sorting>, Never> {
        return editedSortingOption
            .prepend(nil)
            .withLatestFrom(userTokensReorderer.sortingOptionPublisher) { (currentValue: $1, newValue: $0) }
            .eraseToAnyPublisher()
    }

    init(
        userTokensReorderer: UserTokensReordering,
        initialGroupingOption: UserTokensReorderingOptions.Grouping? = nil,
        initialSortingOption: UserTokensReorderingOptions.Sorting? = nil
    ) {
        self.userTokensReorderer = userTokensReorderer
        editedGroupingOption = .init(initialGroupingOption)
        editedSortingOption = .init(initialSortingOption)
    }
}

// MARK: - OrganizeTokensOptionsProviding protocol conformance

extension OrganizeTokensOptionsManager: OrganizeTokensOptionsProviding {
    var groupingOption: UserTokensReorderingOptions.Grouping {
        return userTokensReorderer.groupingOption
    }

    var sortingOption: UserTokensReorderingOptions.Sorting {
        return userTokensReorderer.sortingOption
    }

    var groupingOptionPublisher: AnyPublisher<UserTokensReorderingOptions.Grouping, Never> {
        let editedGroupingOption = editedGroupingOption
            .compactMap { $0 }
            .removeDuplicates()
            .eraseToAnyPublisher()

        let currentGroupingOption = userTokensReorderer
            .groupingOptionPublisher
            .prefix(untilOutputFrom: editedGroupingOption)
            .eraseToAnyPublisher()

        return [
            editedGroupingOption,
            currentGroupingOption,
        ].merge()
    }

    var sortingOptionPublisher: AnyPublisher<UserTokensReorderingOptions.Sorting, Never> {
        let editedSortingOption = editedSortingOption
            .compactMap { $0 }
            .removeDuplicates()
            .eraseToAnyPublisher()

        let currentSortingOption = userTokensReorderer
            .sortingOptionPublisher
            .prefix(untilOutputFrom: editedSortingOption)
            .eraseToAnyPublisher()

        return [
            editedSortingOption,
            currentSortingOption,
        ].merge()
    }
}

// MARK: - OrganizeTokensOptionsEditing protocol conformance

extension OrganizeTokensOptionsManager: OrganizeTokensOptionsEditing {
    func group(by groupingOption: UserTokensReorderingOptions.Grouping) {
        editedGroupingOption.send(groupingOption)
    }

    func sort(by sortingOption: UserTokensReorderingOptions.Sorting) {
        editedSortingOption.send(sortingOption)
    }

    func save(reorderedWalletModelIds: [WalletModelId.ID], source: UserTokensReorderingSource) -> AnyPublisher<Void, Never> {
        return .just
            .withLatestFrom(userTokensReorderer.orderedWalletModelIds, groupingOptionToSave, sortingOptionToSave)
            .withWeakCaptureOf(self)
            .flatMapLatest { input in
                let (manager, (orderedWalletModelIds, groupingOption, sortingOption)) = input
                var reorderingActions: [UserTokensReorderingAction] = []

                if let newValue = groupingOption.newValue, newValue != groupingOption.currentValue {
                    reorderingActions.append(.setGroupingOption(option: newValue))
                }

                if let newValue = sortingOption.newValue, newValue != sortingOption.currentValue {
                    reorderingActions.append(.setSortingOption(option: newValue))
                }

                if reorderedWalletModelIds != orderedWalletModelIds {
                    reorderingActions.append(.reorder(reorderedWalletModelIds: reorderedWalletModelIds))
                }

                return manager.userTokensReorderer.reorder(reorderingActions, source: source)
            }
            .eraseToAnyPublisher()
    }
}
