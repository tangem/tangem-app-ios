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
    func openSend(amountToSend: Amount, blockchainNetwork: BlockchainNetwork, cardViewModel: CardViewModel, walletModel: WalletModel)
    func openSendToSell(amountToSend: Amount, destination: String, tag: String?, blockchainNetwork: BlockchainNetwork, cardViewModel: CardViewModel, walletModel: WalletModel)
    func openBankWarning(confirmCallback: @escaping () -> Void, declineCallback: @escaping () -> Void)
    func openP2PTutorial()
    func openExpress(input: CommonExpressModulesFactory.InputModel)
    func openExplorer(at url: URL)
}
