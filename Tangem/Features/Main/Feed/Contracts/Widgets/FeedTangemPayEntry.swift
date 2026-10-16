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
    case residencyRequired(any TangemPayResidencyInteractor)
    case regionUnavailable(TangemPayUnavailableRegion, any TangemPayResidencyInteractor)
    case kycDeclined(TangemPayKYCInteractor)
    case selectPlan(any TangemPayTariffPlanSelector, wallet: UserWalletModel)

    static func resolve(customer: any TangemPayAccountModel, wallet: UserWalletModel) -> Self? {
        switch customer.state {
        case .kycRequired(let interactor):
            return .kycRequired(interactor)
        case .residencyRequired(let interactor):
            return .residencyRequired(interactor)
        case .regionUnavailable(let region, let interactor):
            return .regionUnavailable(region, interactor)
        case .kycDeclined(let interactor):
            return .kycDeclined(interactor)
        case .planSelectNeeded(let tariffPlanSelector):
            return .selectPlan(tariffPlanSelector, wallet: wallet)
        case .none, .loading, .syncNeeded, .syncInProgress, .unavailable, .failedToIssueCard, .tangemPayAccount, .cardDeactivated:
            return nil
        }
    }
}
