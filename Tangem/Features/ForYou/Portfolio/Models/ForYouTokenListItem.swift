//
//  ForYouTokenListItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// One asset row plus its per-network breakdown revealed on expand.
struct ForYouTokenListItem: Identifiable, Equatable {
    let id: String
    let assetRow: ForYouTokenRow
    let networkRows: [ForYouTokenRow]
    var isExpanded: Bool
    let isExpandable: Bool
}
