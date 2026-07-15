//
//  PortfolioTokenItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct PortfolioTokenItemView: View {
    let item: ForYouTokenListItem
    let onAssetTap: (String) -> Void

    var body: some View {
        if item.isExpandable {
            expandableCard
        } else {
            staticCard
        }
    }
}

private extension PortfolioTokenItemView {
    // MARK: - Expandable asset group

    /// Reuses the shared `ExpandableItemView` (as on the main screen) for the collapse/expand
    /// mechanics, animation and haptics — we only supply the row content.
    var expandableCard: some View {
        ExpandableItemView(
            isExpanded: item.isExpanded,
            backgroundColor: DesignSystem.Color.bgSecondary,
            cornerRadius: Constants.cornerRadius,
            expandedViewTransition: Constants.expandedContentTransition,
            collapsedView: {
                RowView(data: item.assetRow, showsIndicator: true)
                    .padding(16)
            },
            expandedView: {
                ExpandedNetworksView(networkRows: item.networkRows)
            },
            expandedViewHeader: {
                ExpandedHeaderView(assetRow: item.assetRow)
            },
            onExpandedChange: { _ in onAssetTap(item.id) }
        )
    }

    // MARK: - Non-expandable card ("Other", single-network assets, loading skeletons)

    var staticCard: some View {
        RowView(data: item.assetRow, showsIndicator: true)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
    }
}

// MARK: - Constants

private extension PortfolioTokenItemView {
    enum Constants {
        static let cornerRadius: CGFloat = 24

        /// Matches the main-screen expandable item (`ExpandableAccountItemView`).
        static var expandedContentTransition: AnyTransition {
            .asymmetric(
                insertion: .offset(y: 20).combined(with: .opacity),
                removal: .opacity
            )
        }
    }
}

// MARK: - Previews

#Preview("Collapsed") {
    let icon = TokenIconInfo(
        name: "",
        blockchainIconAsset: nil,
        imageURL: IconURLBuilder().tokenIconURL(id: "bitcoin"),
        isCustom: false,
        customTokenColor: nil
    )

    return PortfolioTokenItemView(
        item: ForYouTokenListItem(
            id: "btc",
            assetRow: ForYouTokenRowData(
                id: "btc",
                isLoading: false,
                symbol: "Bitcoin",
                tokenIconInfo: icon,
                sentiment: .positive,
                subtitle: .text("Main network"),
                end: .values(fiat: "$849", percent: "8.49%")
            ),
            networkRows: [],
            isExpanded: false,
            isExpandable: true
        ),
        onAssetTap: { _ in }
    )
    .padding(16)
}

#Preview("Expanded") {
    func icon(_ id: String, network: ImageType? = nil) -> TokenIconInfo {
        TokenIconInfo(
            name: "",
            blockchainIconAsset: network,
            imageURL: IconURLBuilder().tokenIconURL(id: id),
            isCustom: false,
            customTokenColor: nil
        )
    }

    return PortfolioTokenItemView(
        item: ForYouTokenListItem(
            id: "eth",
            assetRow: ForYouTokenRowData(
                id: "eth",
                isLoading: false,
                symbol: "Ethereum",
                tokenIconInfo: icon("ethereum"),
                sentiment: .negative,
                subtitle: .text("2 networks"),
                end: .values(fiat: "$5,231", percent: "25.94%")
            ),
            networkRows: [
                ForYouTokenRowData(
                    id: "eth-mainnet",
                    isLoading: false,
                    symbol: "ETH",
                    tokenIconInfo: icon("ethereum", network: Tokens.ethereumFill),
                    sentiment: .negative,
                    subtitle: .dotted("Ethereum", "1.24 ETH"),
                    end: .values(fiat: "$3,980", percent: "19.73%")
                ),
                ForYouTokenRowData(
                    id: "eth-arbitrum",
                    isLoading: false,
                    symbol: "ETH",
                    tokenIconInfo: icon("ethereum", network: Tokens.arbitrumFill),
                    sentiment: .positive,
                    subtitle: .dotted("Arbitrum", "0.31 ETH"),
                    end: .values(fiat: "$995", percent: "4.93%")
                ),
            ],
            isExpanded: true,
            isExpandable: true
        ),
        onAssetTap: { _ in }
    )
    .padding(16)
}
