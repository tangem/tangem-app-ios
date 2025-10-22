//
//  NewTokenSelectorGroupedSectionViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAccounts

final class NewTokenSelectorGroupedSectionViewModel: Identifiable {
    let header: HeaderType
    let items: [NewTokenSelectorItemViewModel]

    init(header: HeaderType, items: [NewTokenSelectorItemViewModel]) {
        self.header = header
        self.items = items
    }
}

extension NewTokenSelectorGroupedSectionViewModel {
    enum HeaderType: Hashable {
        case wallet(String)
        case account(icon: AccountIconView.ViewData, name: String)
    }
}
