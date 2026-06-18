//
//  TangemPayTransactionDetailsDisplayModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayTransactionDetailsDisplayModel {
    let headerTitle: String
    let headerSubtitle: String
    let icon: Icon
    let amount: String
    let amountSubtitle: String?
    let status: TangemPayTransactionStatusView.Model?
    let rows: [Row]
    let mainButtonAction: TangemPayTransactionDetailsViewModel.MainButtonAction
}

extension TangemPayTransactionDetailsDisplayModel {
    enum Icon {
        case merchantLogo(URL?)
        case withdrawal
        case deposit
        case fee
    }

    struct Row {
        let title: String
        let value: String
    }
}
