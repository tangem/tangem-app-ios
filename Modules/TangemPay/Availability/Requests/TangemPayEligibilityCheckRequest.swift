//
//  TangemPayEligibilityCheckRequest.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayEligibilityCheckRequest: Encodable {
    let product: TangemPayProduct
    let countryCode: String
    let regionCode: String?

    enum CodingKeys: String, CodingKey {
        case product
        case countryCode = "country_code"
        case regionCode = "region_code"
    }
}
