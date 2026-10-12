//
//  GeoSelectionItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct GeoSelectionItem: Identifiable, Equatable {
    let id: String
    let title: String
    let flagURL: URL?
}

// MARK: - Previews

#if DEBUG
extension GeoSelectionItem {
    static let previewCountries = [
        GeoSelectionItem(id: "DE", title: "Germany", flagURL: nil),
        GeoSelectionItem(id: "FR", title: "France", flagURL: nil),
        GeoSelectionItem(id: "US", title: "United States of America", flagURL: nil),
    ]

    static let previewRegions = [
        GeoSelectionItem(id: "US-AL", title: "Alabama", flagURL: nil),
        GeoSelectionItem(id: "US-AZ", title: "Arizona", flagURL: nil),
        GeoSelectionItem(id: "US-CA", title: "California", flagURL: nil),
    ]
}
#endif
