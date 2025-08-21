//
//  PromocodeActivationResponse.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct PromocodeActivationResponse: Decodable {
    let promoCodeId: Int
    let status: String
}
