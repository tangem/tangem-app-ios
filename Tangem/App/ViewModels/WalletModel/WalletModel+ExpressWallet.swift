//
//  WalletModel+ExpressWallet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import BlockchainSdk

extension WalletModel: ExpressWallet {
    var expressCurrency: TangemExpress.ExpressCurrency {
        tokenItem.expressCurrency
    }

    var decimalCount: Int {
        tokenItem.decimalCount
    }

    var feeCurrencyDecimalCount: Int {
        feeTokenItem.decimalCount
    }

    var isFeeCurrency: Bool {
        tokenItem == feeTokenItem
    }

    func getBalance() throws -> Decimal {
        guard let balanceValue else {
            throw ExpressManagerError.amountNotFound
        }

        return balanceValue
    }

    func getFeeCurrencyBalance() -> Decimal {
        wallet.feeCurrencyBalance(amountType: amountType)
    }
}
