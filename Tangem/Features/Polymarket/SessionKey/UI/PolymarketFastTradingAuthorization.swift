//
//  PolymarketFastTradingAuthorization.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemPolymarket

enum PolymarketFastTradingAuthorization: Equatable {
    case enable
    case reenable
    case renew
    case repair
    case replace(previous: PolymarketSessionKey, revokesPrevious: Bool)

    init?(assessment: PolymarketFastTradingAssessment) {
        if assessment.isOperationInFlight || assessment.hasSettlingChange {
            return nil
        }

        if assessment.isRenewDue {
            self = .renew
            return
        }

        switch assessment.status {
        case .offerEnable:
            self = .enable
        case .reenable(let own):
            self = own.status == .revoked ? .enable : .reenable
        case .repairByRenewal:
            self = .repair
        case .replace(let previous, let revokesPrevious):
            self = .replace(previous: previous, revokesPrevious: revokesPrevious)
        case .enabling, .active, .paused, .revoking, .exchangeUnreadable, .waitingForSettlement:
            return nil
        }
    }

    var title: String {
        switch self {
        case .enable, .replace: Localization.commonActivate
        case .reenable, .repair: PolymarketFastTradingStrings.reactivate
        case .renew: PolymarketFastTradingStrings.extend
        }
    }

    var progressMessage: String {
        switch self {
        case .enable, .reenable, .repair, .replace: PolymarketFastTradingStrings.activationInProgress
        case .renew: PolymarketFastTradingStrings.extensionInProgress
        }
    }
}

// MARK: - Pending change

extension PolymarketFastTradingAuthorization {
    static func pendingChangeNotice(for assessment: PolymarketFastTradingAssessment) -> String? {
        guard let settlingKey = assessment.settlingKey else {
            return nil
        }

        guard settlingKey.status == .revoking, assessment.activeOrPausedLocalKey == nil else {
            return PolymarketFastTradingStrings.changeInProgress
        }

        return PolymarketFastTradingStrings.revocationPending
    }
}
