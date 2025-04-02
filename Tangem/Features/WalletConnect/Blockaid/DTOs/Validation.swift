//
//  Validation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension BlockaidDTO {
    struct Validation: Decodable {
        let status: Status
        let resultType: ResultType
        let description: String
        let reason: String
        let classification: String
        let error: String?
    }
}
