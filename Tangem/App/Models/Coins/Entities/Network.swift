//
//  Network.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension CoinsResponse {
    struct Network: Codable {
        public let networkId: String
        public let contractAddress: String?
        public let decimalCount: Int?
    }
}
