//
//  MockForYouPortfolioDataSource.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Feeds the Portfolio Review screen with static mock data: plays a loading → content sequence so
/// the running screen shows both states without the live data pipeline.
struct MockForYouPortfolioDataSource: ForYouPortfolioDataSource {
    var statePublisher: AnyPublisher<PortfolioReviewState, Never> {
        let content = Just(Self.mockContent)
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)

        return Just(PortfolioReviewState.loadingPlaceholder)
            .append(content)
            .eraseToAnyPublisher()
    }
}

// MARK: - Mock content

private extension MockForYouPortfolioDataSource {
    static var mockContent: PortfolioReviewState {
        .content(
            PortfolioReviewState.Content(
                tokenList: [
                    assetItem(
                        id: "btc",
                        symbol: "Bitcoin",
                        subtitle: .text("Main network"),
                        fiat: "$8,491.20",
                        percent: "42.10%",
                        sentiment: .positive
                    ),
                    assetItem(
                        id: "eth",
                        symbol: "Ethereum",
                        subtitle: .text("3 networks"),
                        fiat: "$5,231.00",
                        percent: "25.94%",
                        sentiment: .negative,
                        expandable: true,
                        networkRows: [
                            row(
                                id: "eth-mainnet",
                                symbol: "ETH",
                                subtitle: .dotted("Ethereum", "1.24 ETH"),
                                fiat: "$3,980.00",
                                percent: "19.73%",
                                sentiment: .negative
                            ),
                            row(
                                id: "eth-arbitrum",
                                symbol: "ETH",
                                subtitle: .dotted("Arbitrum", "0.31 ETH"),
                                fiat: "$995.00",
                                percent: "4.93%",
                                sentiment: .negative
                            ),
                            row(
                                id: "eth-base",
                                symbol: "ETH",
                                subtitle: .dotted("Base", "0.08 ETH"),
                                fiat: "$256.00",
                                percent: "1.28%",
                                sentiment: .positive
                            ),
                        ]
                    ),
                    assetItem(
                        id: "sol",
                        symbol: "Solana",
                        subtitle: .text("Main network"),
                        fiat: "$3,120.50",
                        percent: "15.47%",
                        sentiment: .positive
                    ),
                    assetItem(
                        id: "usdc",
                        symbol: "USDC",
                        subtitle: .text("2 networks"),
                        fiat: "$2,000.00",
                        percent: "9.91%",
                        sentiment: .neutral,
                        expandable: true,
                        networkRows: [
                            row(
                                id: "usdc-eth",
                                symbol: "USDC",
                                subtitle: .dotted("Ethereum", "1,000 USDC"),
                                fiat: "$1,000.00",
                                percent: "4.95%",
                                sentiment: .neutral
                            ),
                            row(
                                id: "usdc-polygon",
                                symbol: "USDC",
                                subtitle: .dotted("Polygon", "1,000 USDC"),
                                fiat: "$1,000.00",
                                percent: "4.95%",
                                sentiment: .neutral
                            ),
                        ]
                    ),
                    otherItem(assetCount: 7, fiat: "$1,320.00", percent: "6.54%"),
                ],
                periodSegments: ForYouPeriodSegment.all
            )
        )
    }

    static func assetItem(
        id: String,
        symbol: String,
        subtitle: ForYouTokenRowData.Subtitle,
        fiat: String,
        percent: String,
        sentiment: ForYouTokenRowData.Sentiment,
        expandable: Bool = false,
        networkRows: [ForYouTokenRowData] = []
    ) -> ForYouTokenListItem {
        ForYouTokenListItem(
            id: id,
            assetRow: row(
                id: id,
                symbol: symbol,
                subtitle: subtitle,
                fiat: fiat,
                percent: percent,
                sentiment: sentiment
            ),
            networkRows: networkRows,
            isExpanded: false,
            isExpandable: expandable
        )
    }

    static func otherItem(assetCount: Int, fiat: String, percent: String) -> ForYouTokenListItem {
        ForYouTokenListItem(
            id: "other",
            assetRow: ForYouTokenRowData(
                id: "other",
                isLoading: false,
                symbol: "Other",
                tokenIconInfo: nil,
                sentiment: nil,
                subtitle: .text("\(assetCount) assets"),
                end: .values(fiat: fiat, percent: percent)
            ),
            networkRows: [],
            isExpanded: false,
            isExpandable: false
        )
    }

    static func row(
        id: String,
        symbol: String,
        subtitle: ForYouTokenRowData.Subtitle,
        fiat: String,
        percent: String,
        sentiment: ForYouTokenRowData.Sentiment
    ) -> ForYouTokenRowData {
        ForYouTokenRowData(
            id: id,
            isLoading: false,
            symbol: symbol,
            tokenIconInfo: nil,
            sentiment: sentiment,
            subtitle: subtitle,
            end: .values(fiat: fiat, percent: percent)
        )
    }
}
