//
//  SendRoutableMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

class SendRoutableMock: SendRoutable {
    init() {}

    func dismiss() {}
    func openMail(with dataCollector: EmailDataCollector, recipient: String) {}
    func explore(url: URL) {}
    func share(url: URL) {}
    func openQRScanner(with codeBinding: Binding<String>, networkName: String) {}
    func presentNetworkCurrency(for walletModel: WalletModel, userWalletModel: UserWalletModel) {}
}
