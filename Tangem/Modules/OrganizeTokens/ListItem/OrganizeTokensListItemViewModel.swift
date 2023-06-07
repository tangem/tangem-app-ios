//
//  OrganizeTokensListItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct OrganizeTokensListItemViewModel: Hashable, Identifiable {
    var id = UUID()
    var tokenName: String
    var tokenTotalSum: String
    var isDraggable: Bool
    var tokenIconViewModel: TokenIconViewModel
}
