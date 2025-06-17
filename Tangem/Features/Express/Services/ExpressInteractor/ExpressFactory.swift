//
//  ExpressFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct ExpressFactory {
    func makeExpressSourceWallet(walletModel: any WalletModel) -> ExpressSourceWallet {
        let feeProvider = CommonExpressFeeProvider(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            provider: walletModel,
            ethereumNetworkProvider: walletModel.ethereumNetworkProvider
        )

        let allowanceChecker = AllowanceChecker(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            address: walletModel.defaultAddress.value,
            ethereumNetworkProvider: walletModel.ethereumNetworkProvider,
            ethereumTransactionDataBuilder: walletModel.ethereumTransactionDataBuilder
        )

        let allowanceProvider = CommonAllowanceProvider(
            tokenItem: walletModel.tokenItem,
            allowanceChecker: allowanceChecker
        )

        return ExpressSourceWallet(
            address: walletModel.defaultAddress.value,
            currency: walletModel.tokenItem.expressCurrency,
            feeCurrency: walletModel.feeTokenItem.expressCurrency,
            feeProvider: feeProvider,
            allowanceProvider: allowanceProvider,
            balanceProvider: walletModel
        )
    }

    func makeExpressSourceWallet(wallet: ExpressWalletModel) -> ExpressSourceWallet {
        ExpressSourceWallet(
            address: wallet.defaultAddressString,
            currency: wallet.expressCurrency,
            feeCurrency: wallet.expressFeeCurrency,
            feeProvider: wallet.expressFeeProvider,
            allowanceProvider: wallet.expressAllowanceProvider,
            balanceProvider: wallet.expressBalanceProvider
        )
    }
}
