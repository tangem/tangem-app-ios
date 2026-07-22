//
//  EarnAccountListItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct EarnAccountListItem: Identifiable, Equatable {
    let id: String
    let account: EarnAccountRowData
    let tokens: [EarnTokenRowData]
    let isExpanded: Bool
    let isExpandable: Bool

    func toggledExpansion() -> Self {
        .init(
            id: id,
            account: account,
            tokens: tokens,
            isExpanded: !isExpanded,
            isExpandable: isExpandable
        )
    }
}
