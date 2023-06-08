//
//  PromotionNetworkModels.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct PromotionParameters: Decodable {
    let startTimestamp: Double
    let endTimestamp: Double
}

struct PromotionValidationResult: Decodable {
    let valid: Bool
}

struct PromotionAwardResult: Decodable {
    let status: Bool
}
