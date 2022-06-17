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
    var dismissAction: () -> Void = {}
    
    //MARK: - Child view models
    @Published var sendViewModel: SendViewModel!
    @Published var mailViewModel: MailViewModel? = nil
    @Published var qrScanViewModel: QRScanViewModel? = nil
    
    func start(amountToSend: Amount, blockchainNetwork: BlockchainNetwork, cardViewModel: CardViewModel) {
        sendViewModel = SendViewModel(amountToSend: amountToSend,
                                      blockchainNetwork: blockchainNetwork,
                                      cardViewModel: cardViewModel,
                                      coordinator: self)
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
