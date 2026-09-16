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
    let suggestedSectionTitle: String?
    let allSectionTitle: String?
    let showsSuggestedSection: Bool
    let showsBackButton: Bool
}

// MARK: - Navigation

extension GeoSelectionConfiguration {
    var leadingPolicy: TopNavigation.LeadingPolicy {
        showsBackButton ? .automatic : .none
    }
}
