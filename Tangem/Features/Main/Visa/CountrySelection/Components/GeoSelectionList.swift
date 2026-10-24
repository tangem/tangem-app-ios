//
//  GeoSelectionList.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum GeoSelectionList: Equatable {
    case sections(highlighted: GeoSelectionItem?, all: [GeoSelectionItem])
    case searchResults([GeoSelectionItem])

    var isEmpty: Bool {
        switch self {
        case .sections(let highlighted, let all):
            highlighted == nil && all.isEmpty
        case .searchResults(let items):
            items.isEmpty
        }
    }
}
