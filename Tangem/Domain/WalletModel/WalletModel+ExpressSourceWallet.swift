//
//  WalletModel+ExpressSourceWallet.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

extension WalletModel {
    var address: String? { defaultAddress.value }
    var currency: TangemExpress.ExpressWalletCurrency { tokenItem.expressCurrency }
    var feeCurrency: TangemExpress.ExpressWalletCurrency { feeTokenItem.expressCurrency }

    var feeProvider: any TangemExpress.FeeProvider {
        CommonExpressFeeProvider(wallet: self)
    }

    var allowanceProvider: any TangemExpress.AllowanceProvider {
        CommonAllowanceProvider(walletModel: self)
    }

    var balanceProvider: any TangemExpress.BalanceProvider {
        CommonExpressBalanceProvider(tokenItem: tokenItem, availableBalanceProvider: availableBalanceProvider, feeProvider: self)
    }
}
