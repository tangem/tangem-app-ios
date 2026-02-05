//
//  SendAmountFinishSmallAmountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

struct SendAmountFinishSmallAmountViewModel {
    let tokenHeader: SendTokenHeader
    let tokenIconInfo: TokenIconInfo
    let amountDecimalNumberTextFieldViewModel: DecimalNumberTextFieldViewModel
    let amountFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    let alternativeAmount: String?
}
