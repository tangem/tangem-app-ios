//
//  BitcoinfeesResponse.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct BitcoinfeesResponse: Codable {
    let fastestFee: Int
    let halfHourFee : Int
    let hourFee: Int
}
