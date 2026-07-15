//
//  MockForYouPortfolioDataSource.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Static mock for the Portfolio Review screen: loading → content, so both states render without
/// the live pipeline. Fixtures are intentionally terse — not part of review.
struct MockForYouPortfolioDataSource {
    var statePublisher: AnyPublisher<PortfolioReviewState, Never> {
        Just(PortfolioReviewState.loadingPlaceholder)
            .append(Just(Self.content).delay(for: .seconds(1), scheduler: DispatchQueue.main))
            .eraseToAnyPublisher()
    }
}

// MARK: - Fixtures

private extension MockForYouPortfolioDataSource {
    static var content: PortfolioReviewState {
        .content(.init(
            tokenList: [
                asset("btc", "Bitcoin", .text("Main network"), "$8,491.20", "42.10%", .positive),
                asset("eth", "Ethereum", .text("2 networks"), "$5,231.00", "25.94%", .negative, networks: [
                    row("eth-1", "ETH", .dotted("Ethereum", "1.24 ETH"), "$3,980.00", "19.73%", .negative),
                    row("eth-2", "ETH", .dotted("Arbitrum", "0.31 ETH"), "$995.00", "4.93%", .positive),
                ]),
                asset("other", "Other", .text("7 assets"), "$1,320.00", "6.54%", nil),
            ],
            periodSegments: ForYouPeriodSegment.all
        ))
    }

    static func asset(
        _ id: String, _ symbol: String, _ subtitle: ForYouTokenRowData.Subtitle,
        _ fiat: String, _ percent: String, _ sentiment: ForYouTokenRowData.Sentiment?,
        networks: [ForYouTokenRowData] = []
    ) -> ForYouTokenListItem {
        ForYouTokenListItem(
            id: id,
            assetRow: row(id, symbol, subtitle, fiat, percent, sentiment),
            networkRows: networks,
            isExpanded: false,
            isExpandable: !networks.isEmpty
        )
    }

    static func row(
        _ id: String, _ symbol: String, _ subtitle: ForYouTokenRowData.Subtitle,
        _ fiat: String, _ percent: String, _ sentiment: ForYouTokenRowData.Sentiment?
    ) -> ForYouTokenRowData {
        ForYouTokenRowData(
            id: id, isLoading: false, symbol: symbol, tokenIconInfo: nil,
            sentiment: sentiment, subtitle: subtitle, end: .values(fiat: fiat, percent: percent)
        )
    }
}
