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
    private let userTokensReorderer: UserTokensReordering
    private let editingThrottleInterval: TimeInterval
    private let editedGroupingOption = PassthroughSubject<OrganizeTokensOptions.Grouping, Never>()
    private let editedSortingOption = PassthroughSubject<OrganizeTokensOptions.Sorting, Never>()

    init(
        userTokensReorderer: UserTokensReordering,
        editingThrottleInterval: TimeInterval
    ) {
        self.userTokensReorderer = userTokensReorderer
        self.editingThrottleInterval = editingThrottleInterval
    }
}

// MARK: - OrganizeTokensOptionsProviding protocol conformance

extension OrganizeTokensOptionsManager: OrganizeTokensOptionsProviding {
    var groupingOption: AnyPublisher<OrganizeTokensOptions.Grouping, Never> {
        let editedGroupingOption = editedGroupingOption
            .throttle(
                for: RunLoop.SchedulerTimeType.Stride(editingThrottleInterval),
                scheduler: RunLoop.main,
                latest: false
            )
            .eraseToAnyPublisher()

        let currentGroupingOption = userTokensReorderer
            .groupingOption
            .prefix(untilOutputFrom: editedGroupingOption)
            .eraseToAnyPublisher()

        return [
            editedGroupingOption,
            currentGroupingOption,
        ].merge()
    }

    var sortingOption: AnyPublisher<OrganizeTokensOptions.Sorting, Never> {
        let editedSortingOption = editedSortingOption
            .throttle(
                for: RunLoop.SchedulerTimeType.Stride(editingThrottleInterval),
                scheduler: RunLoop.main,
                latest: false
            )
            .eraseToAnyPublisher()

        let currentSortingOption = userTokensReorderer
            .sortingOption
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
    func group(by groupingOption: OrganizeTokensOptions.Grouping) {
        editedGroupingOption.send(groupingOption)
    }

    func sort(by sortingOption: OrganizeTokensOptions.Sorting) {
        editedSortingOption.send(sortingOption)
    }

    func save(
        reorderedWalletModelIds: [WalletModel.ID]
    ) -> AnyPublisher<Void, Never> {
        return .just
            .withLatestFrom(groupingOption, sortingOption)
            .withWeakCaptureOf(self)
            .flatMapLatest { input in
                let (manager, (grouping, sorting)) = input

                return manager.userTokensReorderer.reorder([
                    .setGroupingOption(option: grouping),
                    .setSortingOption(option: sorting),
                    .reorder(reorderedWalletModelIds: reorderedWalletModelIds),
                ])
            }
            .eraseToAnyPublisher()
    }
}
