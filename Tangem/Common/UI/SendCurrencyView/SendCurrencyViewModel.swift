//
//  SendCurrencyViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SendCurrencyViewModel: ObservableObject, Identifiable {
    @Published private(set) var expressCurrencyViewModel: ExpressCurrencyViewModel
    @Published private(set) var decimalNumberTextFieldStateObject: DecimalNumberTextField.StateObject

    init(
        expressCurrencyViewModel: ExpressCurrencyViewModel,
        decimalNumberTextFieldStateObject: DecimalNumberTextField.StateObject
    ) {
        self.expressCurrencyViewModel = expressCurrencyViewModel
        self.decimalNumberTextFieldStateObject = decimalNumberTextFieldStateObject
    }

    func textFieldDidTapped() {
        Analytics.log(.swapSendTokenBalanceClicked)
    }

    func update(wallet: WalletModel, initialWalletId: Int) {
        expressCurrencyViewModel.update(wallet: .loaded(wallet), initialWalletId: initialWalletId)
        decimalNumberTextFieldStateObject.update(maximumFractionDigits: wallet.decimalCount)
    }

    func updateSendFiatValue(amount: Decimal?, tokenItem: TokenItem) {
        expressCurrencyViewModel.updateFiatValue(expectAmount: amount, tokenItem: tokenItem)
    }
}
