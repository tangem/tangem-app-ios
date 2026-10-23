//
//  MoralisAPIError.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct MoralisAPIError: Decodable, LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}
