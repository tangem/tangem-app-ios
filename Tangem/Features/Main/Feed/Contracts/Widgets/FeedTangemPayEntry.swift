//
//  FeedTangemPayEntry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

enum FeedTangemPayEntry {
    case offer(TangemPayWalletSelectionType)
    case kycRequired(TangemPayKYCInteractor)
    case kycDeclined(TangemPayKYCInteractor)
    case selectPlan(any TangemPayTariffPlanSelector, wallet: UserWalletModel)

    static func resolve(offer: TangemPayWalletSelectionType?, customer: (any TangemPayAccountModel)?, wallet: UserWalletModel) -> Self? {
        guard let customer else {
            return offer.map(Self.offer)
        }

        switch customer.state {
        case .kycRequired(let interactor):
            return .kycRequired(interactor)
        case .kycDeclined(let interactor):
            return .kycDeclined(interactor)
        case .planSelectNeeded(let tariffPlanSelector):
            return .selectPlan(tariffPlanSelector, wallet: wallet)
        case .none, .loading, .syncNeeded, .syncInProgress, .unavailable, .failedToIssueCard, .tangemPayAccount, .cardDeactivated:
            return nil
        }
    }
}
