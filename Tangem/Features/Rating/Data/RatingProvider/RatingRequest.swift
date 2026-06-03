//
//  RatingRequest.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct RatingRequest: Equatable, Sendable {
    let transactionId: String
    let rating: Int
    let feedback: String?
    let provider: String
    let userWalletIdHash: String
    let txUrl: String?
}
