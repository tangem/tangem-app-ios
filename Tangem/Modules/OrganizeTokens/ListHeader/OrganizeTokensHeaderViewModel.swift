//
//  OrganizeTokensHeaderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

final class OrganizeTokensHeaderViewModel: ObservableObject {
    @Published var isSortByBalanceEnabled = true

    var sortByBalanceButtonTitle: String {
        return Localization.organizeTokensSortByBalance
    }

    @Published var isGroupingEnabled = true

    var groupingButtonTitle: String {
        return isGroupingEnabled
            ? Localization.organizeTokensGroup
            : Localization.organizeTokensUngroup
    }

    func toggleSortState() {
        isSortByBalanceEnabled.toggle()
        // [REDACTED_TODO_COMMENT]
    }

    func toggleGroupState() {
        isGroupingEnabled.toggle()
        // [REDACTED_TODO_COMMENT]
    }
}
