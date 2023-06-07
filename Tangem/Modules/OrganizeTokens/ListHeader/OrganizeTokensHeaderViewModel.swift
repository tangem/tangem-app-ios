//
//  OrganizeTokensHeaderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

final class OrganizeTokensHeaderViewModel: ObservableObject {
    @Published var isLeadingButtonSelected = true

    var leadingButtonTitle: String {
        return Localization.organizeTokensSortByBalance
    }

    @Published var isTrailingButtonSelected = true

    var trailingButtonTitle: String {
        return isTrailingButtonSelected
            ? Localization.organizeTokensGroup
            : Localization.organizeTokensUngroup
    }

    func onLeadingButtonTap() {
        isLeadingButtonSelected.toggle()
        // [REDACTED_TODO_COMMENT]
    }

    func onTrailingButtonTap() {
        isTrailingButtonSelected.toggle()
        // [REDACTED_TODO_COMMENT]
    }
}
