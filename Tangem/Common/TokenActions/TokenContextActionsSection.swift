//
//  TokenContextActionsSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TokenContextActionsSection: Identifiable, Hashable {
    let items: [TokenActionType]

    var id: Int { hashValue }
}
