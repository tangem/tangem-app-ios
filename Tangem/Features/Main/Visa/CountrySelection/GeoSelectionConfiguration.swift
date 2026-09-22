//
//  GeoSelectionConfiguration.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

struct GeoSelectionConfiguration {
    let title: String
    let highlight: Highlight?
    let showsBackButton: Bool
}

// MARK: - Highlight

extension GeoSelectionConfiguration {
    enum Highlight {
        case suggested(sectionTitle: String, allSectionTitle: String)
        case selected(code: String, sectionTitle: String, allSectionTitle: String)

        var sectionTitle: String {
            switch self {
            case .suggested(let sectionTitle, _), .selected(_, let sectionTitle, _):
                sectionTitle
            }
        }

        var allSectionTitle: String {
            switch self {
            case .suggested(_, let allSectionTitle), .selected(_, _, let allSectionTitle):
                allSectionTitle
            }
        }
    }
}

// MARK: - Navigation

extension GeoSelectionConfiguration {
    var leadingPolicy: TopNavigation.LeadingPolicy {
        showsBackButton ? .automatic : .none
    }
}
