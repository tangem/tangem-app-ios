//
//  OrganizeTokensListSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct OrganizeTokensListSectionViewModel: Hashable, Identifiable {
    var id = UUID()
    var title: String
    var isDraggable: Bool
    var items: [OrganizeTokensListItemViewModel]
}
