//
//  AmountSummaryViewData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import struct TangemUI.TokenIconInfo

struct AmountSummaryViewData: Identifiable {
    let id = UUID()

    let headerType: ExpressCurrencyHeaderType
    let amount: String
    let amountFiat: String
    let tokenIconInfo: TokenIconInfo
}
