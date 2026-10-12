//
//  OfframpAccountSuggestion.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct OfframpAccountSuggestion: Identifiable, Equatable {
    let id: String
    let matchedPrefix: String
    let accountNumberSuffix: String
    let name: String
}
