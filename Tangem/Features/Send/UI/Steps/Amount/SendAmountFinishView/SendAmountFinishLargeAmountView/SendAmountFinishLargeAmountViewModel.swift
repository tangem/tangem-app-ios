//
//  SendAmountFinishLargeAmountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

struct SendAmountFinishLargeAmountViewModel {
    let tokenHeader: SendTokenHeader?
    let tokenIconInfo: TokenIconInfo
    let amountText: String
    let alternativeAmount: String?

    init(
        tokenHeader: SendTokenHeader,
        tokenIconInfo: TokenIconInfo,
        amountText: String,
        alternativeAmount: String?
    ) {
        self.tokenHeader = switch tokenHeader {
        case .action,
             .wallet:
            nil // Preserves existing behavior: no token header in these cases
        case .account:
            tokenHeader
        }

        self.tokenIconInfo = tokenIconInfo
        self.amountText = amountText
        self.alternativeAmount = alternativeAmount
    }
}
