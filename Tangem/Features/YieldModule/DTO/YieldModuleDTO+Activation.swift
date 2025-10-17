//
//  YieldModuleDTO+Activation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension YieldModuleDTO.Response {
    struct ActivateInfo: Decodable {
        let tokenAddress: String
        let chainId: Int
        let isActive: Bool
        let activatedAt: Date
    }
}
