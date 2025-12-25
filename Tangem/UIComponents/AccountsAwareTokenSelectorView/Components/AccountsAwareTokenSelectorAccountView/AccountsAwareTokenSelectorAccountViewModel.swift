//
//  AccountsAwareTokenSelectorAccountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemAccounts

final class AccountsAwareTokenSelectorAccountViewModel: ObservableObject, Identifiable {
    let header: HeaderType
    @Published private(set) var items: [AccountsAwareTokenSelectorItemViewModel]?

    var itemsCountPublisher: AnyPublisher<Int, Never> {
        // The first value emitted by `$items` is the initial placeholder value (before
        // `itemsPublisher` assigns the actual data), which would otherwise produce an
        // incorrect count. We drop that initial emission as a workaround until
        // `AccountsAwareTokenSelectorViewModelsMapper` provides the initial items
        // synchronously in its `init`, after which this `dropFirst()` should be removed.
        $items.dropFirst().compactMap { $0?.count }.eraseToAnyPublisher()
    }

    init(
        header: HeaderType,
        itemsPublisher: AnyPublisher<[AccountsAwareTokenSelectorItemViewModel], Never>,
    ) {
        self.header = header

        itemsPublisher.eraseToOptional().receiveOnMain().assign(to: &$items)
    }
}

extension AccountsAwareTokenSelectorAccountViewModel {
    enum HeaderType: Hashable {
        case wallet(String)
        case account(icon: AccountIconView.ViewData, name: String)
    }
}
