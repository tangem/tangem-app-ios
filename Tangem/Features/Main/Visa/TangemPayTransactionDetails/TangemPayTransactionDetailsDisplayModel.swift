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
    var cardRow: CardRowState?
    var cashbackRow: CashbackRowState?
}

extension TangemPayTransactionDetailsDisplayModel {
    enum Icon {
        case merchantLogo(URL?)
        case withdrawal
        case deposit
        case cashback
        case fee
    }

    struct Row {
        let title: String
        let value: String
        let accessibilityIdentifier: String?

        init(title: String, value: String, accessibilityIdentifier: String? = nil) {
            self.title = title
            self.value = value
            self.accessibilityIdentifier = accessibilityIdentifier
        }
    }

    struct CashbackRow: Equatable {
        let value: Value
        let subvalue: String?

        enum Value: Equatable {
            case amount(String)
            case text(String)
        }
    }

    enum CardRowState: Equatable {
        case loading
        case loaded(cardNumberEnd: String, cardName: String?)
        case failed
    }

    enum CashbackRowState: Equatable {
        case loading
        case awaitingCalculation
        case loaded(CashbackRow)
        case failed
    }
}
