//
//  OnrampProviderProcessingTimeFormatter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemLocalization

struct OnrampProviderProcessingTimeFormatter {
    func format(_ processingTimeType: OnrampPaymentMethod.ProcessingTime) -> String {
        switch processingTimeType {
        case .instant:
            Localization.onrampInstantStatus
        case .days(let days):
            Localization.onrampTimingDays(days)
        case .minutes(let min, let max):
            Localization.onrampTimingMinutes("\(min)\(AppConstants.enDashSign)\(max)")
        }
    }
}
