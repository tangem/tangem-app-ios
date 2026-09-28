//
//  CollectiblesPrize.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CollectiblesPrize: Identifiable {
    let id: String
    let name: String
    let imageURL: URL?
    /// The grader and grade as one label, like `PSA 9`; `nil` for an ungraded card.
    let grade: String?
    /// Appraised value in dollars.
    let insuredValue: Decimal?
}
