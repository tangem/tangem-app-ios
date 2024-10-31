//
//  Network.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct NetworkModel: Codable {
    let networkId: String
    let contractAddress: String?
    let decimalCount: Int?
}
