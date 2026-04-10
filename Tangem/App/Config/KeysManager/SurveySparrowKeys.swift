//
//  SurveySparrowKeys.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct SurveySparrowKeys: Decodable {
    let domain: String

    // [REDACTED_TODO_COMMENT]
    init(from decoder: any Decoder) throws {
        let debugDomain = "tangem.surveysparrow.com"
        domain = debugDomain
    }
}
