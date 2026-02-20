//
//  SingleTokenRoutableMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import struct TangemUIUtils.AlertBinder

class SingleTokenRoutableMock: SingleTokenRoutable {
    var errorAlertPublisher: AnyPublisher<AlertBinder?, Never> { .just(output: nil) }

    func openReceive(walletModel: any WalletModel) {}

    func openBuy(walletModel: any WalletModel) {}

    func openSend(walletModel: any WalletModel) {}

    func openSwap(walletModel: any WalletModel) {}

    func openExchange(walletModel: any WalletModel) {}

    func openStaking(walletModel: any WalletModel) {}

    func openSell(for walletModel: any WalletModel) {}

    func openSendToSell(with request: SellCryptoRequest, for walletModel: any WalletModel) {}

    func openExplorer(at url: URL, for walletModel: any WalletModel) {}

    func openMarketsTokenDetails(for tokenItem: TokenItem) {}

    func openInSafari(url: URL) {}

    func openOnramp(walletModel: any WalletModel) {}

    func openPendingExpressTransactionDetails(pendingTransaction: PendingTransaction, tokenItem: TokenItem, pendingTransactionsManager: any PendingExpressTransactionsManager) {}

    func openYieldModule(walletModel: any WalletModel) {}
}
