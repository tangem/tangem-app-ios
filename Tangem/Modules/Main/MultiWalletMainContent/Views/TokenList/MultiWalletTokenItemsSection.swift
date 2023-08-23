//
//  MultiWalletTokenItemsSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
struct MultiWalletTokenItemsSection: Identifiable {
    var id: Int
    let title: String?
    let tokenItemModels: [TokenItemViewModel]

    init(
        id: Int,
        title: String?,
        tokenItemModels: [TokenItemViewModel]
    ) {
        self.id = id
        self.title = title
        self.tokenItemModels = tokenItemModels
    }
}
