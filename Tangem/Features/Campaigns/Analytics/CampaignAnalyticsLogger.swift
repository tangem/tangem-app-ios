//
//  CampaignAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CampaignAnalyticsLogger {
    private let campaign: CashbackCampaign

    init(campaign: CashbackCampaign) {
        self.campaign = campaign
    }

    func logPromotionScreenOpened() {
        Analytics.log(event: .promotionScreenOpened, params: [.screen: campaignValue.rawValue])
    }

    func logEnrollButtonClicked(tokenItem: TokenItem) {
        Analytics.log(
            event: .promotionEnrollButtonClicked,
            params: [
                .campaign: campaignValue.rawValue,
                .token: tokenItem.currencySymbol.uppercased(),
                .blockchain: tokenItem.blockchain.displayName.capitalizingFirstLetter(),
            ]
        )
    }

    func logAlreadyEnrolledScreenOpened() {
        Analytics.log(.promotionAlreadyEnrolledScreenOpened)
    }
}

// MARK: - Private

private extension CampaignAnalyticsLogger {
    var campaignValue: Analytics.ParameterValue {
        switch campaign {
        case .whaleSwap: .cashback
        case .reactivation: .reactivation
        }
    }
}
