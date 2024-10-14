//
//  AlgorandResponse+Error.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension AlgorandResponse {
    struct Error: Decodable, LocalizedError {
        let message: String
        
        var errorDescription: String? {
            message
        }
    }
}
