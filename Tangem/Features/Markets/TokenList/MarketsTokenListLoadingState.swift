//
//  MarketsTokenListLoadingState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemMacro

@CaseFlagable
enum MarketsTokenListLoadingState: String, Identifiable, Hashable {
    case noResults
    case error
    case loading
    case allDataLoaded
    case idle

    var id: String { rawValue }
}
