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
    var statePublisher: AnyPublisher<PortfolioReviewViewModel.ViewState, Never> {
        Just(PortfolioReviewViewModel.ViewState.loading)
            .append(Just(Self.content).delay(for: .seconds(2), scheduler: DispatchQueue.main))
            .eraseToAnyPublisher()
    }
}

// MARK: - Fixtures

private extension MockForYouPortfolioDataSource {
    static var content: PortfolioReviewViewModel.ViewState {
        .content(.init(
            tokenList: [
                asset("btc", "Bitcoin", .text("2 networks"), "$8,491.20", "42.10%", .positive, expanded: true, networks: [
                    row("btc-1", "BTC", .dotted("Bitcoin", "0.09 BTC"), "$6,491.20", "32.19%", .positive),
                    row("btc-2", "BTC", .dotted("Lightning", "0.03 BTC"), "$2,000.00", "9.91%", .neutral),
                ]),
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
        expanded: Bool = false,
        networks: [ForYouTokenRowData] = []
    ) -> ForYouTokenListItem {
        ForYouTokenListItem(
            id: id,
            assetRow: row(id, symbol, subtitle, fiat, percent, sentiment),
            networkRows: networks,
            isExpanded: expanded,
            isExpandable: !networks.isEmpty
        )
    }

    static func row(
        _ id: String, _ symbol: String, _ subtitle: ForYouTokenRowData.Subtitle,
        _ fiat: String, _ percent: String, _ sentiment: ForYouTokenRowData.Sentiment?
    ) -> ForYouTokenRowData {
        ForYouTokenRowData(
            id: id, symbol: symbol, tokenIconInfo: nil,
            sentiment: sentiment, subtitle: subtitle, end: .values(fiat: fiat, percent: percent)
        )
    }
}
