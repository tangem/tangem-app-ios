//
//  SendRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

protocol SendRoutable: SendFeeRoutable, SendFinishRoutable, AnyObject {
    func dismiss()
    func openMail(with dataCollector: EmailDataCollector, recipient: String)
    func openQRScanner(with codeBinding: Binding<String>, networkName: String)
    func openFeeCurrency(for walletModel: WalletModel, userWalletModel: UserWalletModel) // aka presentFeeCurrency
}
