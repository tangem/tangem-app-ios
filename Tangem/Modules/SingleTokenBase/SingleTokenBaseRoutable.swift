//
//  SingleTokenBaseRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSwapping

protocol SingleTokenBaseRoutable: AnyObject {
    func openReceiveScreen(amountType: Amount.AmountType, blockchain: Blockchain, addressInfos: [ReceiveAddressInfo])
    func openBuyCrypto(at url: URL, closeUrl: String, action: @escaping (String) -> Void)
    func openSellCrypto(at url: URL, sellRequestUrl: String, action: @escaping (String) -> Void)
    func openSend(amountToSend: Amount, blockchainNetwork: BlockchainNetwork, cardViewModel: CardViewModel, walletModel: WalletModel)
    func openSendToSell(amountToSend: Amount, destination: String, blockchainNetwork: BlockchainNetwork, cardViewModel: CardViewModel, walletModel: WalletModel)
    func openBankWarning(confirmCallback: @escaping () -> Void, declineCallback: @escaping () -> Void)
    func openP2PTutorial()
    func openSwapping(input: CommonSwappingModulesFactory.InputModel)
    func openExplorer(at url: URL, blockchainDisplayName: String)
}
