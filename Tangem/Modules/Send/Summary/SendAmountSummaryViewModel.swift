//
//  SendAmountSummaryViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

class SendAmountSummaryViewModel: Identifiable {
    let amount: String
    let amountFiat: String
    let tokenIconName: String
    let tokenIconURL: URL?
    let tokenIconCustomTokenColor: Color?
    let tokenIconBlockchainIconName: String?
    let isCustomToken: Bool

    init(
        amount: String,
        amountFiat: String,
        tokenIconName: String,
        tokenIconURL: URL?,
        tokenIconCustomTokenColor: Color?,
        tokenIconBlockchainIconName: String?,
        isCustomToken: Bool

    ) {
        self.amount = amount
        self.amountFiat = amountFiat
        self.tokenIconName = tokenIconName
        self.tokenIconURL = tokenIconURL
        self.tokenIconCustomTokenColor = tokenIconCustomTokenColor
        self.tokenIconBlockchainIconName = tokenIconBlockchainIconName
        self.isCustomToken = isCustomToken
    }
}
