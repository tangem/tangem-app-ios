//
//  AppCoordinator+TokenDetailsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension AppCoordinator: TokenDetailsRoutable {
    func openBuyCrypto(at url: URL, closeUrl: String, action: @escaping (String) -> Void) {
        pushedWebViewModel = WebViewContainerViewModel(url: url,
                                                       title: "wallet_button_topup".localized,
                                                       addLoadingIndicator: true,
                                                       urlActions: [
                                                        closeUrl: {[weak self] response in
                                                            self?.pushedWebViewModel = nil
                                                            action(response)
                                                        }])
    }
    
    func openSellCrypto(at url: URL, sellRequestUrl: String, action: @escaping (String) -> Void) {
        pushedWebViewModel = WebViewContainerViewModel(url: url,
                                                       title: "wallet_button_sell_crypto".localized,
                                                       addLoadingIndicator: true,
                                                       urlActions: [sellRequestUrl: action])
    }
    
    func openExplorer(at url: URL, blockchainDisplayName: String) {
        modalWebViewModel = WebViewContainerViewModel(url: url,
                                                      title: "common_explorer_format".localized(blockchainDisplayName),
                                                      withCloseButton: true)
    }
    
    func openSend(amountToSend: Amount, blockchainNetwork: BlockchainNetwork, cardViewModel: CardViewModel) {
        let coordinator = SendCoordinator()
        coordinator.start(amountToSend: amountToSend, blockchainNetwork: blockchainNetwork, cardViewModel: cardViewModel)
        self.sendCoordinator = coordinator
    }
    
    func openSendToSell(amountToSend: Amount, destination: String, blockchainNetwork: BlockchainNetwork, cardViewModel: CardViewModel) {
        let coordinator = SendCoordinator()
        coordinator.start(amountToSend: amountToSend, destination: destination, blockchainNetwork: blockchainNetwork, cardViewModel: cardViewModel)
        self.sendCoordinator = coordinator
    }
    
    func openPushTx(for tx: BlockchainSdk.Transaction, blockchainNetwork: BlockchainNetwork, card: CardViewModel) {
        let coordinator = PushTxCoordinator()
        coordinator.start(for: tx, blockchainNetwork: blockchainNetwork, card: card)
        self.pushTxCoordinator = coordinator
    }
}
