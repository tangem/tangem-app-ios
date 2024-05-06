//
//  SendWalletInfo.swift
//  Tangem
//
//  Created by Andrey Chukavin on 24.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

#warning("TODO: reformat, regroup, refactor?")
struct SendWalletInfo {
    let walletName: String
    let balanceValue: Decimal?
    let balance: String
    let blockchain: Blockchain
    let currencyId: String?
    let amountType: Amount.AmountType
    let decimalCount: Int
    let feeCurrencySymbol: String
    let feeCurrencyId: String?
    let isFeeApproximate: Bool
    let tokenIconInfo: TokenIconInfo
    let cryptoIconURL: URL?
    let cryptoCurrencyCode: String
    let fiatIconURL: URL?
    let fiatCurrencyCode: String
    let amountFractionDigits: Int
    let feeFractionDigits: Int
    let feeAmountType: Amount.AmountType
    let canUseFiatCalculation: Bool
}
