//
//  TokenSelectorAccountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemAccounts

final class TokenSelectorAccountViewModel: ObservableObject, Identifiable {
    let header: HeaderType
    let expandableViewModel: TokenSelectorExpandableAccountItemViewModel?
    @Published private(set) var items: [TokenSelectorItemViewModel] = []

    var itemsCountPublisher: AnyPublisher<Int, Never> {
        $items.compactMap { $0.count }.eraseToAnyPublisher()
    }

    init(
        header: HeaderType,
        itemsPublisher: AnyPublisher<[TokenSelectorItemViewModel], Never>,
        expandableViewModel: TokenSelectorExpandableAccountItemViewModel? = nil
    ) {
        self.header = header
        self.expandableViewModel = expandableViewModel

        itemsPublisher.receiveOnMain().assign(to: &$items)
    }
}

extension TokenSelectorAccountViewModel {
    enum HeaderType: Hashable {
        case wallet(String)
        case account(icon: AccountIconView.ViewData, name: String)
    }
}
