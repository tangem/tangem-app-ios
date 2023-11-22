//
//  SendCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class SendCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: SendViewModel?

    // MARK: - Child coordinators

    // MARK: - Child view models

    @Published var mailViewModel: MailViewModel? = nil

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = SendViewModel(
            walletModel: options.walletModel,
            transactionSigner: options.transactionSigner,
            sendType: options.type,
            emailData: options.userWalletModel.emailData,
            emailConfig: options.userWalletModel.config.emailConfig ?? EmailConfig.default,
            coordinator: self
        )
    }
}

// MARK: - Options

extension SendCoordinator {
    struct Options {
        let userWalletModel: UserWalletModel
        let walletModel: WalletModel
        let transactionSigner: TransactionSigner
        let type: SendType
    }
}

// MARK: - SendRoutable

extension SendCoordinator: SendRoutable {
    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: .failedToSendTx)
    }
}
