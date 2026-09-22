//
//  YieldModuleDTO+Enveloped.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension YieldModuleDTO {
    /// Unwraps the `{success, timestamp, result}` envelope of the `/yield-modules/*` endpoints.
    /// Errors arrive as non-2xx statuses, so `success` is not inspected.
    struct Enveloped<T: Decodable>: Decodable {
        let result: T
    }
}
