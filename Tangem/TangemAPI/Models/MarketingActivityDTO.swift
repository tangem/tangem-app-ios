//
//  MarketingActivityDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum MarketingActivityDTO {
    enum BindWallets {
        struct Request: Encodable, Equatable {
            let walletIds: [String]
        }
    }
}
