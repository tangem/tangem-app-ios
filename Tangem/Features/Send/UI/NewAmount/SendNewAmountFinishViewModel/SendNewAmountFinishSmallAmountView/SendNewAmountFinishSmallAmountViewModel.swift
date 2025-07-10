//
//  SendNewAmountFinishSmallAmountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemUI

class SendNewAmountFinishSmallAmountViewModel: ObservableObject {
    @Published private(set) var title: String
    @Published private(set) var tokenIconInfo: TokenIconInfo
    @Published private(set) var amountDecimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published private(set) var amountFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published private(set) var alternativeAmount: String?

    init(
        title: String,
        tokenIconInfo: TokenIconInfo,
        amountDecimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel,
        amountFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions,
        alternativeAmount: String?
    ) {
        self.title = title
        self.tokenIconInfo = tokenIconInfo
        self.amountDecimalNumberTextFieldViewModel = amountDecimalNumberTextFieldViewModel
        self.amountFieldOptions = amountFieldOptions
        self.alternativeAmount = alternativeAmount
    }
}
