//
//  MarketsTokenDetailsSecurityScoreRatingViewData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsTokenDetailsSecurityScoreRatingViewData {
    struct RatingBullet {
        let value: Double
    }

    let ratingBullets: [RatingBullet]
    let securityScore: String
}
