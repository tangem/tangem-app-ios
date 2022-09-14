//
//  PushTxCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class PushTxCoordinator: CoordinatorObject {
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Main view model
    @Published private(set) var pushTxViewModel: PushTxViewModel? = nil

    // MARK: - Child view models
    @Published var mailViewModel: MailViewModel? = nil

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: PushTxCoordinator.Options) {
        pushTxViewModel = PushTxViewModel(transaction: options.tx,
                                          blockchainNetwork: options.blockchainNetwork,
                                          cardViewModel: options.cardModel,
                                          coordinator: self)
    }
}

extension PushTxCoordinator {
    struct Options {
        let tx: BlockchainSdk.Transaction
        let blockchainNetwork: BlockchainNetwork
        let cardModel: CardViewModel
    }
}

extension PushTxCoordinator: PushTxRoutable {
    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        mailViewModel = MailViewModel(dataCollector: dataCollector, recipient: recipient, emailType: .failedToPushTx)
    }
}
