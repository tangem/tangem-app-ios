//
//  TokenItem+CampaignAnalytics.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension TokenItem {
    var campaignAnalyticsParams: [Analytics.ParameterKey: String] {
        [
            .token: currencySymbol.uppercased(),
            .blockchain: blockchain.displayName.capitalizingFirstLetter(),
        ]
    }
}
