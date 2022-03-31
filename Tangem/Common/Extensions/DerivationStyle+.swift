//
//  DerivationStyle+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension DerivationStyle {
    init(with batchId: String) {
        let batchId = batchId.uppercased()
        
        if batchId == "AC01" || batchId == "AC02" {
            self = .legacy
        }
        
        self = .new
    }
}
