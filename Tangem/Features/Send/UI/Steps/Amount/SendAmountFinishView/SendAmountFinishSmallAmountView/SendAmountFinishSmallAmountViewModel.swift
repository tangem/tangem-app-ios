//
//  SendAmountFinishSmallAmountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemUI

class SendAmountFinishSmallAmountViewModel: ObservableObject {
    @Published private(set) var tokenHeader: SendTokenHeader
    @Published private(set) var tokenIconInfo: TokenIconInfo
    @Published private(set) var amountDecimalNumberTextFieldViewModel: DecimalNumberTextFieldViewModel
    @Published private(set) var amountFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published private(set) var alternativeAmount: String?

    init(
        tokenHeader: SendTokenHeader,
        tokenIconInfo: TokenIconInfo,
        amountDecimalNumberTextFieldViewModel: DecimalNumberTextFieldViewModel,
        amountFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions,
        alternativeAmount: String?
    ) {
        self.tokenHeader = tokenHeader
        self.tokenIconInfo = tokenIconInfo
        self.amountDecimalNumberTextFieldViewModel = amountDecimalNumberTextFieldViewModel
        self.amountFieldOptions = amountFieldOptions
        self.alternativeAmount = alternativeAmount
    }
}
