//
//  SendAmountSummaryViewData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendAmountSummaryViewData: Identifiable {
    let id = UUID()

    let title: String
    let amount: String
    let amountAlternative: String
    let tokenIconInfo: TokenIconInfo
}
