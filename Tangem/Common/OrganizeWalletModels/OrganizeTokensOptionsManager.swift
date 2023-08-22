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

    private static func userTokenListUpdate(
        currentValue: OrganizeTokensOptions.Grouping,
        newValue: OrganizeTokensOptions.Grouping?
    ) -> UserTokenListUpdateType? {
        guard let newValue = newValue, newValue != currentValue else { return nil }

        return .group(newValue)
    }

    private static func userTokenListUpdate(
        currentValue: OrganizeTokensOptions.Sorting,
        newValue: OrganizeTokensOptions.Sorting?
    ) -> UserTokenListUpdateType? {
        guard let newValue = newValue, newValue != currentValue else { return nil }

        return .sort(newValue)
    }

    private static func userTokenListUpdate(
        reorderedWalletModelIds: [WalletModel.ID],
        existingUserTokens: [StorageEntry.V3.Entry],
        sortingNewValue: OrganizeTokensOptions.Sorting?
    ) -> UserTokenListUpdateType? {
        // Re-orderings made as a result of sorting user tokens by balance are ignored
        guard sortingNewValue != .byBalance else { return nil }

        var existingUserTokensKeyedByWalletModelIds: [WalletModel.ID: StorageEntry.V3.Entry] = [:]
        var walletModelIdsFromExistingUserTokens: [WalletModel.ID] = []

        for userToken in existingUserTokens {
            let walletModelId = userToken.walletModelId
            walletModelIdsFromExistingUserTokens.append(walletModelId)
            existingUserTokensKeyedByWalletModelIds[walletModelId] = userToken
        }

        // Checking if any re-ordering has actually taken place
        guard walletModelIdsFromExistingUserTokens != reorderedWalletModelIds else { return nil }

        let reorderedUserTokens = reorderedWalletModelIds.compactMap { existingUserTokensKeyedByWalletModelIds[$0] }

        assert(
            reorderedWalletModelIds.count == existingUserTokens.count && reorderedUserTokens.count == existingUserTokens.count,
            "Method expects a re-ordered, but not modified (by adding/removing some entries) list of wallet model identifiers"
        )

        return .rewrite(reorderedUserTokens)
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
        reorderedWalletModelIds: [WalletModel.ID]
    ) -> AnyPublisher<Void, Never> {
        let manager = userTokenListManager

        let groupingOptionPublisher = Just(nil)
            .append(editedGroupingOption)
            .withLatestFrom(userTokenListManager.groupingOptionPublisher) { (currentValue: $1, newValue: $0) }

        let sortingOptionPublisher = Just(nil)
            .append(editedSortingOption)
            .withLatestFrom(userTokenListManager.sortingOptionPublisher) { (currentValue: $1, newValue: $0) }

        return .just
            .withLatestFrom(groupingOptionPublisher, sortingOptionPublisher, userTokenListManager.userTokensPublisher)
            .flatMapLatest { input in
                let (groupingOption, sortingOption, userTokens) = input

                return Deferred {
                    Future<Void, Never> { promise in
                        let updates = [
                            Self.userTokenListUpdate(
                                currentValue: groupingOption.currentValue,
                                newValue: groupingOption.newValue
                            ),
                            Self.userTokenListUpdate(
                                currentValue: sortingOption.currentValue,
                                newValue: sortingOption.newValue
                            ),
                            Self.userTokenListUpdate(
                                reorderedWalletModelIds: reorderedWalletModelIds,
                                existingUserTokens: userTokens,
                                sortingNewValue: sortingOption.newValue
                            ),
                        ].compactMap { $0 }

                        DispatchQueue.main.async {
                            manager.update(updates, shouldUpload: true)
                            promise(.success(()))
                        }
                    }
                }
            }
            .eraseToAnyPublisher()
    }
}
