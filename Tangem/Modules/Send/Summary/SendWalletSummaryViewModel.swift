//
//  SendWalletSummaryViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class SendWalletSummaryViewModel: Identifiable {
    let walletName: String
    let totalBalance: String

    init(walletName: String, totalBalance: String) {
        self.walletName = walletName
        self.totalBalance = totalBalance
    }
}
