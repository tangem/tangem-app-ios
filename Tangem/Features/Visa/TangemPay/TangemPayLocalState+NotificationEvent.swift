//
//  TangemPayLocalState+NotificationEvent.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

extension TangemPayLocalState {
    func errorNotificationEvent(icon: MainButton.Icon?) -> TangemPayNotificationEvent? {
        switch self {
        case .unavailable:
            return .unavailable
        case .syncNeeded:
            return .sessionExpired(icon: icon, isRenewing: false)
        case .syncInProgress:
            return .sessionExpired(icon: icon, isRenewing: true)
        case .loading,
             .kycRequired,
             .kycDeclined,
             .issuingCard,
             .failedToIssueCard,
             .tangemPayAccount,
             .cardDeactivated,
             .planSelectNeeded:
            return nil
        }
    }
}
