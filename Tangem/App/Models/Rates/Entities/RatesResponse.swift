//
//  RatesResponse.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct RatesResponse: Codable {
    let rates: [String: Decimal]
}
