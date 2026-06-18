//
//  ExpressDTO.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum ExpressDTO {
    // MARK: - Common

    struct Currency: Codable {
        let contractAddress: String
        let network: String
    }

    // MARK: - Error

    enum APIError {
        struct Response: Decodable {
            let error: ExpressAPIError
        }
    }
}
