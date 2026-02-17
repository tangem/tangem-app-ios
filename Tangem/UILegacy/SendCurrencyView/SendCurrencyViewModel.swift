//
//  SendCurrencyViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress

class SendCurrencyViewModel: ObservableObject, Identifiable {
    @Published private(set) var expressCurrencyViewModel: ExpressCurrencyViewModel
    @Published private(set) var decimalNumberTextFieldViewModel: DecimalNumberTextFieldViewModel
    @Published private(set) var isInputDisabled: Bool = false

    init(
        expressCurrencyViewModel: ExpressCurrencyViewModel,
        decimalNumberTextFieldViewModel: DecimalNumberTextFieldViewModel
    ) {
        self.expressCurrencyViewModel = expressCurrencyViewModel
        self.decimalNumberTextFieldViewModel = decimalNumberTextFieldViewModel
    }

    func textFieldDidTapped() {
        Analytics.log(.swapSendTokenBalanceClicked)
    }

    func update(wallet: ExpressInteractor.Source, initialWalletId: WalletModelId) {
        expressCurrencyViewModel.update(wallet: wallet.mapValue { $0 as ExpressGenericWallet }, initialWalletId: initialWalletId)

        if let tokenItem = wallet.value?.tokenItem {
            decimalNumberTextFieldViewModel.update(maximumFractionDigits: tokenItem.decimalCount)
        }
    }

    func updateSendFiatValue(amount: Decimal?, tokenItem: TokenItem?) {
        expressCurrencyViewModel.updateFiatValue(expectAmount: amount, tokenItem: tokenItem)
    }

    func update(isInputDisabled: Bool) {
        self.isInputDisabled = isInputDisabled
    }
}
