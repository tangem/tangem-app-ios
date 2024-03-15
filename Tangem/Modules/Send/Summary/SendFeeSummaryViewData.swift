//
//  SendFeeSummaryViewData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendFeeSummaryViewData: Identifiable {
    let id = UUID()

    let title: String
    let cryptoAmount: String
    let fiatAmount: String

    var feeOption: FeeOption {
        .market
    }
}
