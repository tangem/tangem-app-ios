//
//  ExpressFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct ExpressWalletsFactory {
    let feeProvider: ExpressFeeProvider
    let allowanceProvider: TangemExpress.AllowanceProvider

    func makeExpressSourceWallet(walletModel: any WalletModel) -> ExpressSourceWallet {
        ExpressSourceWallet(
            address: walletModel.defaultAddressString,
            currency: walletModel.tokenItem.expressCurrency,
            feeCurrency: walletModel.feeTokenItem.expressCurrency,
            feeProvider: feeProvider,
            allowanceProvider: allowanceProvider,
            balanceProvider: walletModel
        )
    }

    func makeExpressDestinationWallet(walletModel: any WalletModel) -> ExpressDestinationWallet {
        ExpressDestinationWallet(currency: walletModel.tokenItem.expressCurrency, address: walletModel.defaultAddressString)
    }
}
