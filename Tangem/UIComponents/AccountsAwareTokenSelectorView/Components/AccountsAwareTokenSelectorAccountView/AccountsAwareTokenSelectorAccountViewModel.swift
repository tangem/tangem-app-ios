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
    let expandableViewModel: TokenSelectorExpandableAccountItemViewModel?
    @Published private(set) var items: [AccountsAwareTokenSelectorItemViewModel]

    var itemsCountPublisher: AnyPublisher<Int, Never> {
        $items.compactMap { $0.count }.eraseToAnyPublisher()
    }

    init(
        header: HeaderType,
        items: [AccountsAwareTokenSelectorItemViewModel],
        itemsPublisher: AnyPublisher<[AccountsAwareTokenSelectorItemViewModel], Never>,
        expandableViewModel: TokenSelectorExpandableAccountItemViewModel? = nil
    ) {
        self.header = header
        self.expandableViewModel = expandableViewModel
        self.items = items

        itemsPublisher.receiveOnMain().assign(to: &$items)
    }
}

extension AccountsAwareTokenSelectorAccountViewModel {
    enum HeaderType: Hashable {
        case wallet(String)
        case account(icon: AccountIconView.ViewData, name: String)
    }
}
