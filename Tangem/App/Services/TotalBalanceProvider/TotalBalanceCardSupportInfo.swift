//
//  TotalBalanceSupportData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct TotalBalanceCardSupportInfo {
    let cardBatchId: String
    let cardNumberHash: String

    init(cardBatchId: String, cardNumber: String) {
        self.cardBatchId = cardBatchId
        self.cardNumberHash = cardNumber.sha256Hash.hexString
    }
}
