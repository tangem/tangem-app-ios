//
//  PromotionNetworkModels.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct PromotionValidationResult: Decodable {
    let valid: Bool
}

struct PromotionAwardResult: Decodable {
    let status: Bool
}
