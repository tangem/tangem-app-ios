//
//  EarnHowItWorks.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct EarnHowItWorks: Identifiable, Hashable {
    let steps: [Step]
    let attribution: Attribution
    let learnMoreURL: URL

    var id: Self { self }

    struct Step: Hashable {
        let title: String
        let description: String
    }

    struct Attribution: Hashable {
        let text: String
        let highlighted: String
    }
}
