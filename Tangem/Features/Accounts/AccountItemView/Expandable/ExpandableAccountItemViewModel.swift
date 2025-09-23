//
//  ExpandableAccountItemViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class ExpandableAccountItemViewModel: ObservableObject {
    let accountItemViewModel: AccountItemViewModel
    let groupedTokens: [(name: String, tokens: [TokenItemViewModel])]

    init(accountItemViewModel: AccountItemViewModel, tokens: [TokenItemViewModel]) {
        self.accountItemViewModel = accountItemViewModel
        groupedTokens = Dictionary(grouping: tokens, by: \.tokenItem.blockchain.networkId)
            .map { (name: $0.key, tokens: $0.value) }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }
}
