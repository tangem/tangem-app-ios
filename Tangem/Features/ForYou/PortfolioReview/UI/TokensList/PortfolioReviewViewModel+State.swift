//
//  PortfolioReviewViewModel+State.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PortfolioReviewViewModel {
    /// View-state model for the For You Portfolio Review screen.
    enum ViewState: Equatable {
        case loading
        case content(Content)

        struct Content: Equatable {
            let tokenList: [ForYouTokenListItem]
            let periodSegments: [ForYouPeriodSegment]
            let chart: Chart
            /// Set by the empty state only for the no-amount case, so a real-holdings content never shows the CTA.
            let showsAddFunds: Bool
        }

        /// The donut summary card above the list.
        enum Chart: Equatable {
            case loaded(assets: [SummaryGaugeAsset], assetCount: Int, topHoldingPercent: String)
            case noData(NoData)

            /// Why the chart has nothing to draw — drives the card title and the donut center bubble.
            enum NoData: Equatable {
                case cantLoad
                case noAmount
            }
        }
    }
}
