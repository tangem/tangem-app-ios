//
//  TransactionDetailsRouteData.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemExpress
import TangemUI
import TangemAccounts

struct TransactionDetailsRouteData {
    let transaction: TransactionViewModel
    let record: TransactionRecord?
    let recordUpdates: AnyPublisher<TransactionRecord, Never>
    let walletModel: any WalletModel
    let tokenIconInfo: TokenIconInfo
    let tokenSymbol: String
    let tokenCurrencyId: String?
    let receiverName: String
    let receiverAccountIcon: AccountIconView.ViewData?
    let resolveExpressToken: (ExpressCurrency) -> TokenItem?
}
