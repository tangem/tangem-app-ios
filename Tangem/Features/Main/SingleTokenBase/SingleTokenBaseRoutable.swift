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
    func openReceiveScreen(tokenItem: TokenItem, addressInfos: [ReceiveAddressInfo])
    func openBuyCrypto(at url: URL, action: @escaping () -> Void)
    func openSellCrypto(at url: URL, action: @escaping (String) -> Void)
    func openSend(userWalletModel: UserWalletModel, walletModel: any WalletModel)
    func openSendToSell(amountToSend: Decimal, destination: String, tag: String?, userWalletModel: UserWalletModel, walletModel: any WalletModel)
    func openExpress(input: CommonExpressModulesFactory.InputModel)
    func openStaking(options: StakingDetailsCoordinator.Options)
    func openInSafari(url: URL)
    func openMarketsTokenDetails(tokenModel: MarketsTokenModel)
    func openOnramp(walletModel: any WalletModel, userWalletModel: UserWalletModel)
    func openPendingExpressTransactionDetails(
        pendingTransaction: PendingTransaction,
        tokenItem: TokenItem,
        userWalletModel: UserWalletModel,
        pendingTransactionsManager: PendingExpressTransactionsManager
    )
}
