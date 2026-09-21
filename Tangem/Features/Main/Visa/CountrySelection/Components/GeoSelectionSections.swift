//
//  GeoSelectionSections.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct GeoSelectionSections: Equatable {
    let highlighted: GeoSelectionItem?
    let all: [GeoSelectionItem]

    var isEmpty: Bool {
        highlighted == nil && all.isEmpty
    }
}
