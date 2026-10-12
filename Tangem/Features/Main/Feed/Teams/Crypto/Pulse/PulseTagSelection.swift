//
//  PulseTagSelection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// A CoinGecko category applied to the Market Pulse list, together with the country the list evaluates
/// `restricted_for_country` for. The volatile fields of the category (market cap, asset count) are left out
/// so that re-picking the same filter compares equal.
struct PulseTagSelection: Hashable {
    let id: String
    let name: String
    let country: String?
}
