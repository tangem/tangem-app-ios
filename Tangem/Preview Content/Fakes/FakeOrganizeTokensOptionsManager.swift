//
//  FakeOrganizeTokensOptionsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class FakeOrganizeTokensOptionsManager {
    private let _groupingOption: CurrentValueSubject<UserTokensReorderingOptions.Grouping, Never>
    private let _sortingOption: CurrentValueSubject<UserTokensReorderingOptions.Sorting, Never>

    init(
        initialGroupingOption groupingOption: UserTokensReorderingOptions.Grouping,
        initialSortingOption sortingOption: UserTokensReorderingOptions.Sorting
    ) {
        _groupingOption = .init(groupingOption)
        _sortingOption = .init(sortingOption)
    }
}

// MARK: - OrganizeTokensOptionsProviding protocol conformance

extension FakeOrganizeTokensOptionsManager: OrganizeTokensOptionsProviding {
    var groupingOption: UserTokensReorderingOptions.Grouping {
        return _groupingOption.value
    }

    var sortingOption: UserTokensReorderingOptions.Sorting {
        return _sortingOption.value
    }

    var groupingOptionPublisher: AnyPublisher<UserTokensReorderingOptions.Grouping, Never> {
        return _groupingOption.eraseToAnyPublisher()
    }

    var sortingOptionPublisher: AnyPublisher<UserTokensReorderingOptions.Sorting, Never> {
        return _sortingOption.eraseToAnyPublisher()
    }
}

// MARK: - OrganizeTokensOptionsEditing protocol conformance

extension FakeOrganizeTokensOptionsManager: OrganizeTokensOptionsEditing {
    func group(by groupingOption: UserTokensReorderingOptions.Grouping) {
        _groupingOption.send(groupingOption)
    }

    func sort(by sortingOption: UserTokensReorderingOptions.Sorting) {
        _sortingOption.send(sortingOption)
    }

    func save(reorderedWalletModelIds: [WalletModelId.ID], source: UserTokensReorderingSource) -> AnyPublisher<Void, Never> {
        return .just
    }
}
