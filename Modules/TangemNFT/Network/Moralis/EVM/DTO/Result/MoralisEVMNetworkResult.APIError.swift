//
//  MoralisNetworkResult.APIError.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension MoralisEVMNetworkResult {
    struct APIError: Decodable {
        let message: String
    }
}
