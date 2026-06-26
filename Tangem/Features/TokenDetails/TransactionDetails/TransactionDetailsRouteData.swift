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

/// Everything the coordinator needs to build and present the transaction details sheet. The owning
/// view-model resolves the live app state (token icon/symbol, receiver, token resolver, record + its
/// updates); the coordinator owns presentation and navigation.
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
