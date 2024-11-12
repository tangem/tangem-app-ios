//
//  SendRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemExpress

protocol SendRoutable: SendFeeRoutable, SendDestinationRoutable, OnrampRoutable, OnrampAmountRoutable, AnyObject {
    func dismiss()
    func openMail(with dataCollector: EmailDataCollector, recipient: String)
    func openQRScanner(with codeBinding: Binding<String>, networkName: String)
    func openFeeCurrency(for walletModel: WalletModel, userWalletModel: UserWalletModel)
    func openExplorer(url: URL)
    func openShareSheet(url: URL)
    func openApproveView(settings: ExpressApproveViewModel.Settings, approveViewModelInput: any ApproveViewModelInput)
}
