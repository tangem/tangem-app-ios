//
//  SingleTokenBaseRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress

protocol SingleTokenBaseRoutable: AnyObject {
    func openReceiveScreen(walletModel: any WalletModel)
    func openSellCrypto(at url: URL, action: @escaping (String) -> Void)
    func openSend(input: SendInput)
    func openSendToSell(input: SendInput, sellParameters: PredefinedSellParameters)
    func openSwap(input: SendInput)
    func openExpress(input: ExpressDependenciesInput)
    func openStaking(options: StakingDetailsCoordinator.Options)
    func openInSafari(url: URL)
    func openMarketsTokenDetails(tokenModel: MarketsTokenModel)
    func openOnramp(input: SendInput, parameters: PredefinedOnrampParameters)
    func openPendingExpressTransactionDetails(
        pendingTransaction: PendingTransaction,
        tokenItem: TokenItem,
        userWalletInfo: UserWalletInfo,
        pendingTransactionsManager: PendingExpressTransactionsManager
    )
}
