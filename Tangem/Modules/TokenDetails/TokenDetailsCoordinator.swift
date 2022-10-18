//
//  TokenDetailsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class TokenDetailsCoordinator: CoordinatorObject {
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Main view model
    @Published private(set) var tokenDetailsViewModel: TokenDetailsViewModel? = nil

    // MARK: - Child coordinators
    @Published var sendCoordinator: SendCoordinator? = nil
    @Published var pushTxCoordinator: PushTxCoordinator? = nil

    // MARK: - Child view models
    @Published var pushedWebViewModel: WebViewContainerViewModel? = nil
    @Published var modalWebViewModel: WebViewContainerViewModel? = nil
    @Published var warningBankCardViewModel: WarningBankCardViewModel? = nil

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: TokenDetailsCoordinator.Options) {
        tokenDetailsViewModel = TokenDetailsViewModel(cardModel: options.cardModel,
                                                      blockchainNetwork: options.blockchainNetwork,
                                                      amountType: options.amountType,
                                                      coordinator: self)
    }
}

extension TokenDetailsCoordinator {
    struct Options {
        let cardModel: CardViewModel
        let blockchainNetwork: BlockchainNetwork
        let amountType: Amount.AmountType
    }
}

extension TokenDetailsCoordinator: TokenDetailsRoutable {
    func openBuyCrypto(at url: URL, closeUrl: String, action: @escaping (String) -> Void) {
        Analytics.log(.topUpScreenOpened)
        pushedWebViewModel = WebViewContainerViewModel(url: url,
                                                       title: "wallet_button_topup".localized,
                                                       addLoadingIndicator: true,
                                                       urlActions: [
                                                           closeUrl: { [weak self] response in
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
        Analytics.log(.sendScreenOpened)
        let coordinator = SendCoordinator { [weak self] in
            self?.sendCoordinator = nil
        }
        let options = SendCoordinator.Options(amountToSend: amountToSend,
                                              destination: nil,
                                              blockchainNetwork: blockchainNetwork,
                                              cardViewModel: cardViewModel)
        coordinator.start(with: options)
        self.sendCoordinator = coordinator
    }

    func openSendToSell(amountToSend: Amount, destination: String, blockchainNetwork: BlockchainNetwork, cardViewModel: CardViewModel) {
        let coordinator = SendCoordinator { [weak self] in
            self?.sendCoordinator = nil
        }
        let options = SendCoordinator.Options(amountToSend: amountToSend,
                                              destination: destination,
                                              blockchainNetwork: blockchainNetwork,
                                              cardViewModel: cardViewModel)
        coordinator.start(with: options)
        self.sendCoordinator = coordinator
    }

    func openPushTx(for tx: BlockchainSdk.Transaction, blockchainNetwork: BlockchainNetwork, card: CardViewModel) {
        let dismissAction: Action = { [weak self] in
            self?.pushTxCoordinator = nil
        }

        let coordinator = PushTxCoordinator(dismissAction: dismissAction)
        let options = PushTxCoordinator.Options(tx: tx,
                                                blockchainNetwork: blockchainNetwork,
                                                cardModel: card)
        coordinator.start(with: options)
        self.pushTxCoordinator = coordinator
    }

    func openBankWarning(confirmCallback: @escaping () -> (), declineCallback: @escaping () -> ()) {
        let delay = 0.6
        warningBankCardViewModel = .init(confirmCallback: { [weak self] in
            self?.warningBankCardViewModel = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                confirmCallback()
            }
        }, declineCallback: { [weak self] in
            self?.warningBankCardViewModel = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                declineCallback()
            }
        })
    }

    func openP2PTutorial() {
        modalWebViewModel = WebViewContainerViewModel(url: URL(string: "https://tangem.com/howtobuy.html")!,
                                                      title: "",
                                                      addLoadingIndicator: true,
                                                      withCloseButton: false,
                                                      urlActions: [:])
    }
}
