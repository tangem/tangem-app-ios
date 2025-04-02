//
//  SolanaScan.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension BlockaidDTO {
    enum SolanaScan {
        struct Request: ScanBlockchainRequest {
            let accountAddress: String?
            let metadata: BlockaidDTO.Metadata
            
            let method: String
            let transactions: [String]
        }
    }
}
