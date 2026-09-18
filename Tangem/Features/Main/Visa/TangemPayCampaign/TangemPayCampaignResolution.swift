//
//  TangemPayCampaignResolution.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPay

enum TangemPayCampaignResolution {
    case landing(TangemPayCampaignLanding)
    case issueCard(TangemPayCampaignIssueCard)
    case unavailable
}

struct TangemPayCampaignLanding {
    let cardArtURL: URL?
    let mode: Mode

    enum Mode {
        case noWallet
        case noPay
    }
}

struct TangemPayCampaignIssueCard {
    let cardArtURL: URL?
    let userWalletModel: UserWalletModel
    let tangemPayAccount: TangemPayAccount
    let fee: TangemPayCustomerOffer.Fee?

    var isBasicTariff: Bool {
        tangemPayAccount.customerTariffPlan?.tariffPlan.type == TangemPayAccount.basicTariffPlanType
    }
}
