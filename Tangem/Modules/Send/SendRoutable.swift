//
//  SendRoutable.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

protocol SendDestinationRoutable: AnyObject {
    func openQRScanner(with codeBinding: Binding<String>, networkName: String)
}

protocol SendRoutable: SendDestinationRoutable, SendFeeRoutable, AnyObject {
    func dismiss()
    func openMail(with dataCollector: EmailDataCollector, recipient: String)
    func openFeeCurrency(for walletModel: WalletModel, userWalletModel: UserWalletModel) // aka presentFeeCurrency
    func openExplorer(url: URL)
    func openShareSheet(url: URL)
}
