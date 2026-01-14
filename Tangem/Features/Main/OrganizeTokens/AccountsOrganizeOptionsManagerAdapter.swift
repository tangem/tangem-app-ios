//
//  AccountsOrganizeOptionsManagerAdapter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

final class AccountsOrganizeOptionsManagerAdapter {
    /// A single instance shared between all accounts.
    private let innerSharedOptionsManager: OrganizeTokensOptionsManager

    /// Cache of editors for each account to preserve their state.
    private var cachedEditors: [ObjectIdentifier: OrganizeTokensOptionsManager] = [:]

    private var editedGroupingOption: UserTokensReorderingOptions.Grouping?
    private var editedSortingOption: UserTokensReorderingOptions.Sorting?

    init(
        userTokensReorderer: UserTokensReordering
    ) {
        innerSharedOptionsManager = OrganizeTokensOptionsManager(userTokensReorderer: userTokensReorderer)
    }

    func optionsEditorForReorder(for cryptoAccountModel: any CryptoAccountModel) -> OrganizeTokensOptionsEditing {
        let cacheKey = ObjectIdentifier(cryptoAccountModel)
        let optionsEditor: OrganizeTokensOptionsManager

        if let cachedOptionsEditor = cachedEditors[cacheKey] {
            optionsEditor = cachedOptionsEditor
        } else {
            optionsEditor = OrganizeTokensOptionsManager(userTokensReorderer: cryptoAccountModel.userTokensManager)
            cachedEditors[cacheKey] = optionsEditor
        }

        if let groupingOption = editedGroupingOption {
            optionsEditor.group(by: groupingOption)
        }

        if let sortingOption = editedSortingOption {
            optionsEditor.sort(by: sortingOption)
        }

        return optionsEditor
    }
}

// MARK: - OrganizeTokensOptionsProviding protocol conformance

extension AccountsOrganizeOptionsManagerAdapter: OrganizeTokensOptionsProviding {
    var groupingOption: UserTokensReorderingOptions.Grouping {
        innerSharedOptionsManager.groupingOption
    }

    var sortingOption: UserTokensReorderingOptions.Sorting {
        innerSharedOptionsManager.sortingOption
    }

    var groupingOptionPublisher: AnyPublisher<UserTokensReorderingOptions.Grouping, Never> {
        innerSharedOptionsManager.groupingOptionPublisher
    }

    var sortingOptionPublisher: AnyPublisher<UserTokensReorderingOptions.Sorting, Never> {
        innerSharedOptionsManager.sortingOptionPublisher
    }
}

// MARK: - OrganizeTokensOptionsEditing protocol conformance

extension AccountsOrganizeOptionsManagerAdapter: OrganizeTokensOptionsEditing {
    func group(by groupingOption: UserTokensReorderingOptions.Grouping) {
        editedGroupingOption = groupingOption
        innerSharedOptionsManager.group(by: groupingOption)
    }

    func sort(by sortingOption: UserTokensReorderingOptions.Sorting) {
        editedSortingOption = sortingOption
        innerSharedOptionsManager.sort(by: sortingOption)
    }

    func save(
        reorderedWalletModelIds: [WalletModelId.ID],
        source: UserTokensReorderingSource
    ) -> AnyPublisher<Void, Never> {
        preconditionFailure("Obtain an editor instance via `optionsEditorForReorder(for:)` and call `\(#function)` on it instead")
    }
}
