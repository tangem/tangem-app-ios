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
    private let userTokenListManager: UserTokenListManager
    private let editedGroupingOption = CurrentValueSubject<OrganizeTokensOptions.Grouping?, Never>(nil)
    private let editedSortingOption = CurrentValueSubject<OrganizeTokensOptions.Sorting?, Never>(nil)

    init(
        userTokenListManager: UserTokenListManager
    ) {
        self.userTokenListManager = userTokenListManager
    }
}

// MARK: - OrganizeTokensOptionsProviding protocol conformance

extension OrganizeTokensOptionsManager: OrganizeTokensOptionsProviding {
    var groupingOption: AnyPublisher<OrganizeTokensOptions.Grouping, Never> {
        let editedGroupingOption = editedGroupingOption
            .compactMap { $0 }
            .eraseToAnyPublisher()

        let groupingOptionFromUserTokenList = userTokenListManager
            .groupingOptionPublisher
            .prefix(untilOutputFrom: editedGroupingOption)
            .eraseToAnyPublisher()

        return [
            editedGroupingOption,
            groupingOptionFromUserTokenList,
        ].merge()
    }

    var sortingOption: AnyPublisher<OrganizeTokensOptions.Sorting, Never> {
        let editedSortingOption = editedSortingOption
            .compactMap { $0 }
            .eraseToAnyPublisher()

        let sortingOptionFromUserTokenList = userTokenListManager
            .sortingOptionPublisher
            .prefix(untilOutputFrom: editedSortingOption)
            .eraseToAnyPublisher()

        return [
            editedSortingOption,
            sortingOptionFromUserTokenList,
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
        walletModelIds: [WalletModel.ID]
    ) -> AnyPublisher<Void, Never> {
        let groupingOptionPublisher = Just(nil)
            .append(editedGroupingOption)
            .withLatestFrom(userTokenListManager.groupingOptionPublisher) { ($0, $1) }

        let sortingOptionPublisher = Just(nil)
            .append(editedSortingOption)
            .withLatestFrom(userTokenListManager.sortingOptionPublisher) { ($0, $1) }

        return .just
            .withLatestFrom(groupingOptionPublisher, sortingOptionPublisher, userTokenListManager.userTokensPublisher)
            .withWeakCaptureOf(self)
            .flatMapLatest { input in
                let (manager, (groupingOption, sortingOption, userTokens)) = input

                return Deferred {
                    Future<Void, Never> { [userTokenListManager = manager.userTokenListManager] promise in
                        // [REDACTED_TODO_COMMENT]
                        var updates: [UserTokenListUpdateType] = []

                        let (groupingNewValue, groupingCurrentValue) = groupingOption
                        if let groupingNewValue = groupingNewValue, groupingNewValue != groupingCurrentValue {
                            updates.append(.group(groupingNewValue))
                        }

                        let (sortingNewValue, sortingCurrentValue) = sortingOption
                        if let sortingNewValue = sortingNewValue, sortingNewValue != sortingCurrentValue {
                            updates.append(.sort(sortingNewValue))
                        }

                        if sortingNewValue != .byBalance {
                            var existingUserTokensKeyedByWalletModelIds: [WalletModel.ID: StorageEntry.V3.Entry] = [:]
                            var walletModelIdsFromExistingUserTokens: [WalletModel.ID] = []

                            for userToken in userTokens {
                                let walletModelId = userToken.walletModelId
                                walletModelIdsFromExistingUserTokens.append(walletModelId)
                                existingUserTokensKeyedByWalletModelIds[walletModelId] = userToken
                            }

                            if walletModelIdsFromExistingUserTokens != walletModelIds {
                                let updatedUserTokens = walletModelIds.compactMap { existingUserTokensKeyedByWalletModelIds[$0] }
                                updates.append(.rewrite(updatedUserTokens))
                            }
                        }

                        DispatchQueue.main.async {
                            userTokenListManager.update(updates, shouldUpload: true)
                        }

                        promise(.success(()))
                    }
                }
            }
            .eraseToAnyPublisher()
    }
}
