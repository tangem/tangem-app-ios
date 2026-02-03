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
    let amountDecimalNumberTextFieldViewModel: DecimalNumberTextFieldViewModel
    let amountFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    let alternativeAmount: String?

    init(
        tokenHeader: SendTokenHeader,
        tokenIconInfo: TokenIconInfo,
        amountDecimalNumberTextFieldViewModel: DecimalNumberTextFieldViewModel,
        amountFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions,
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
        self.amountDecimalNumberTextFieldViewModel = amountDecimalNumberTextFieldViewModel
        self.amountFieldOptions = amountFieldOptions
        self.alternativeAmount = alternativeAmount
    }
}
