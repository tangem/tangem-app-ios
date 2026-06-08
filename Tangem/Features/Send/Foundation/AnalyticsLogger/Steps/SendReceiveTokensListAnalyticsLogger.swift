//
//  SendReceiveTokensListAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SendReceiveTokensListAnalyticsLogger {
    func logSearchClicked()
    func logTokenSearched(coin: CoinModel, searchText: String?)

    func logTokenChosen(token: TokenItem)
    func logSendSwapCantSwapThisToken(token: String)
}
