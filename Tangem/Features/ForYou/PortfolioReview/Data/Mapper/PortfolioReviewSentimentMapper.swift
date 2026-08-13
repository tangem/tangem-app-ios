//
//  PortfolioReviewSentimentMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct PortfolioReviewSentimentMapper {
    private let indicatorsMapper = TokenSummaryIndicatorsMapper()

    func sentiment(
        for readings: [TokenSummaryIndicator]?,
        timeframe: TokenSummaryIndicator.Timeframe
    ) -> ForYouTokenRowData.Sentiment? {
        guard let readings else {
            return nil
        }

        guard let outlook = indicatorsMapper.map(readings: readings, timeframe: timeframe).score?.outlook else {
            return nil
        }

        return ForYouTokenRowData.Sentiment(outlook)
    }
}
