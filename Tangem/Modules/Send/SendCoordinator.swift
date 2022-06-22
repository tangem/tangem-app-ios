//
//  SendCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import SwiftUI

class SendCoordinator: CoordinatorObject {
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>
    
    //MARK: - Main view model
    @Published private(set) var sendViewModel: SendViewModel? = nil
    
    //MARK: - Child view models

    @Published var mailViewModel: MailViewModel? = nil
    @Published var qrScanViewModel: QRScanViewModel? = nil
    
    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }
    
    func start(with options: SendCoordinator.Options) {
        if let destination = options.destination {
            sendViewModel = SendViewModel(amountToSend: options.amountToSend,
                                          destination: destination,
                                          blockchainNetwork: options.blockchainNetwork,
                                          cardViewModel: options.cardViewModel,
                                          coordinator: self)
        } else {
            sendViewModel = SendViewModel(amountToSend: options.amountToSend,
                                          blockchainNetwork: options.blockchainNetwork,
                                          cardViewModel: options.cardViewModel,
                                          coordinator: self)
        }
    }
}

extension SendCoordinator {
    struct Options {
        let amountToSend: Amount
        let destination: String?
        let blockchainNetwork: BlockchainNetwork
        let cardViewModel: CardViewModel
    }
}

extension SendCoordinator: SendRoutable {
    func openMail(with dataCollector: EmailDataCollector) {
        mailViewModel = MailViewModel(dataCollector: dataCollector, support: .tangem, emailType: .failedToSendTx)
    }
    
    func closeModule() {
        dismiss()
    }
    
    func openQRScanner(with codeBinding: Binding<String>) {
        qrScanViewModel = .init(code: codeBinding)
    }
}
