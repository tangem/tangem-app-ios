//
//  SendNewAmountFinishLargeAmountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemUI

class SendNewAmountFinishLargeAmountViewModel: ObservableObject {
    @Published private(set) var tokenIconInfo: TokenIconInfo
    @Published private(set) var amountDecimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published private(set) var amountFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published private(set) var alternativeAmount: String?

    init(
        tokenIconInfo: TokenIconInfo,
        amountDecimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel,
        amountFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions,
        alternativeAmount: String?
    ) {
        self.tokenIconInfo = tokenIconInfo
        self.amountDecimalNumberTextFieldViewModel = amountDecimalNumberTextFieldViewModel
        self.amountFieldOptions = amountFieldOptions
        self.alternativeAmount = alternativeAmount
    }
}
