//
//  TangemTokenRowPreviews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if DEBUG

import SwiftUI

@available(iOS 17, *)
#Preview("Huge Dynamic Type") {
    ScrollView {
        VStack(spacing: 0) {
            // Loaded state - full content
            TangemTokenRow(
                viewData: TangemTokenRowViewData(
                    id: "1",
                    tokenIconInfo: TokenIconInfo(
                        name: "Bitcoin",
                        blockchainIconAsset: nil,
                        imageURL: nil,
                        isCustom: false,
                        customTokenColor: .orange
                    ),
                    name: "Bitcoin",
                    badge: nil,
                    content: .loaded(TangemTokenRowViewData.LoadedContent(
                        balances: TangemTokenRowViewData.Balances(
                            fiat: .value("$45,123.45"),
                            crypto: .value("1.234 BTC")
                        ),
                        priceInfo: TangemTokenRowViewData.PriceInfo(
                            price: "$45,000.00",
                            change: .positive("2.34%")
                        )
                    )),
                    hasMonochromeIcon: false
                )
            )
            .padding()

            Divider()

            // Loading state with cached values
            TangemTokenRow(
                viewData: TangemTokenRowViewData(
                    id: "2",
                    tokenIconInfo: TokenIconInfo(
                        name: "Ethereum",
                        blockchainIconAsset: nil,
                        imageURL: nil,
                        isCustom: false,
                        customTokenColor: .blue
                    ),
                    name: "Ethereum",
                    badge: nil,
                    content: .loading(cached: TangemTokenRowViewData.CachedContent(
                        fiatBalance: "$3,200.00",
                        cryptoBalance: "1.5 ETH",
                        price: "$2,133.33"
                    )),
                    hasMonochromeIcon: false
                )
            )
            .padding()

            Divider()

            // Loading state without cached values
            TangemTokenRow(
                viewData: TangemTokenRowViewData(
                    id: "2b",
                    tokenIconInfo: TokenIconInfo(
                        name: "Ethereum",
                        blockchainIconAsset: nil,
                        imageURL: nil,
                        isCustom: false,
                        customTokenColor: .blue
                    ),
                    name: "Ethereum",
                    badge: nil,
                    content: .loading(cached: nil),
                    hasMonochromeIcon: false
                )
            )
            .padding()

            Divider()

            // With pending transaction badge
            TangemTokenRow(
                viewData: TangemTokenRowViewData(
                    id: "3",
                    tokenIconInfo: TokenIconInfo(
                        name: "Solana",
                        blockchainIconAsset: nil,
                        imageURL: nil,
                        isCustom: false,
                        customTokenColor: .purple
                    ),
                    name: "Solana",
                    badge: .pendingTransaction,
                    content: .loaded(TangemTokenRowViewData.LoadedContent(
                        balances: TangemTokenRowViewData.Balances(
                            fiat: .value("$1,234.56"),
                            crypto: .value("10.5 SOL")
                        ),
                        priceInfo: TangemTokenRowViewData.PriceInfo(
                            price: "$117.57",
                            change: .negative("-1.23%")
                        )
                    )),
                    hasMonochromeIcon: false
                )
            )
            .padding()

            Divider()

            // With rewards badge
            TangemTokenRow(
                viewData: TangemTokenRowViewData(
                    id: "4",
                    tokenIconInfo: TokenIconInfo(
                        name: "Cardano",
                        blockchainIconAsset: nil,
                        imageURL: nil,
                        isCustom: false,
                        customTokenColor: .green
                    ),
                    name: "Cardanoxcxxxcxcxcx",
                    badge: .rewards(TangemTokenRowViewData.RewardsInfo(
                        value: "APY 5.2%",
                        isActive: true,
                        isUpdating: false
                    )),
                    content: .loaded(TangemTokenRowViewData.LoadedContent(
                        balances: TangemTokenRowViewData.Balances(
                            fiat: .value("$5674566789565.89"),
                            crypto: .value("1,234 ADA")
                        ),
                        priceInfo: TangemTokenRowViewData.PriceInfo(
                            price: "$0.46",
                            change: .neutral("0.00%")
                        )
                    )),
                    hasMonochromeIcon: false
                )
            )
            .padding()

            Divider()

            // Failed state with cached balances
            TangemTokenRow(
                viewData: TangemTokenRowViewData(
                    id: "5",
                    tokenIconInfo: TokenIconInfo(
                        name: "Polygon",
                        blockchainIconAsset: nil,
                        imageURL: nil,
                        isCustom: false,
                        customTokenColor: .purple
                    ),
                    name: "Polygon",
                    badge: nil,
                    content: .loaded(TangemTokenRowViewData.LoadedContent(
                        balances: TangemTokenRowViewData.Balances(
                            fiat: .failed(cached: "$89.12"),
                            crypto: .failed(cached: "100 MATIC")
                        ),
                        priceInfo: nil
                    )),
                    hasMonochromeIcon: true
                )
            )
            .padding()

            Divider()

            // Error state
            TangemTokenRow(
                viewData: TangemTokenRowViewData(
                    id: "6",
                    tokenIconInfo: TokenIconInfo(
                        name: "Unknown",
                        blockchainIconAsset: nil,
                        imageURL: nil,
                        isCustom: false,
                        customTokenColor: .gray
                    ),
                    name: "Unknown Token",
                    badge: nil,
                    content: .error(message: "Network error"),
                    hasMonochromeIcon: true
                )
            )
            .padding()

            Divider()

            // Compact state with price
            TangemTokenRow(
                viewData: TangemTokenRowViewData(
                    id: "7",
                    tokenIconInfo: TokenIconInfo(
                        name: "Dogecoin",
                        blockchainIconAsset: nil,
                        imageURL: nil,
                        isCustom: false,
                        customTokenColor: .yellow
                    ),
                    name: "Dogecoin",
                    badge: nil,
                    content: .compact(price: "$0.12"),
                    hasMonochromeIcon: false
                )
            )
            .padding()

            Divider()

            // Compact state without price
            TangemTokenRow(
                viewData: TangemTokenRowViewData(
                    id: "8",
                    tokenIconInfo: TokenIconInfo(
                        name: "Custom Token",
                        blockchainIconAsset: nil,
                        imageURL: nil,
                        isCustom: true,
                        customTokenColor: .red
                    ),
                    name: "Custom Token",
                    badge: nil,
                    content: .compact(price: nil),
                    hasMonochromeIcon: false
                )
            )
            .padding()
        }
    }
    .background(Color.Tangem.Surface.level1)
    .environment(\.dynamicTypeSize, .accessibility2)
}

@available(iOS 17, *)
#Preview("Dark Mode", traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        TangemTokenRow(
            viewData: TangemTokenRowViewData(
                id: "1",
                tokenIconInfo: TokenIconInfo(
                    name: "Bitcoin",
                    blockchainIconAsset: nil,
                    imageURL: nil,
                    isCustom: false,
                    customTokenColor: .orange
                ),
                name: "Bitcoin",
                badge: nil,
                content: .loaded(TangemTokenRowViewData.LoadedContent(
                    balances: TangemTokenRowViewData.Balances(
                        fiat: .value("$45,123.45"),
                        crypto: .value("1.234 BTC")
                    ),
                    priceInfo: TangemTokenRowViewData.PriceInfo(
                        price: "$45,000.00",
                        change: .positive("2.34%")
                    )
                )),
                hasMonochromeIcon: false
            )
        )

        Divider()

        TangemTokenRow(
            viewData: TangemTokenRowViewData(
                id: "2",
                tokenIconInfo: TokenIconInfo(
                    name: "Ethereum",
                    blockchainIconAsset: nil,
                    imageURL: nil,
                    isCustom: false,
                    customTokenColor: .blue
                ),
                name: "Ethereum",
                badge: nil,
                content: .loading(cached: TangemTokenRowViewData.CachedContent(
                    fiatBalance: "$3,200.00",
                    cryptoBalance: "1.5 ETH",
                    price: "$2,133.33"
                )),
                hasMonochromeIcon: false
            )
        )

        Divider()

        TangemTokenRow(
            viewData: TangemTokenRowViewData(
                id: "3",
                tokenIconInfo: TokenIconInfo(
                    name: "Polygon",
                    blockchainIconAsset: nil,
                    imageURL: nil,
                    isCustom: false,
                    customTokenColor: .purple
                ),
                name: "Polygon",
                badge: nil,
                content: .loaded(TangemTokenRowViewData.LoadedContent(
                    balances: TangemTokenRowViewData.Balances(
                        fiat: .failed(cached: "$89.12"),
                        crypto: .failed(cached: "100 MATIC")
                    ),
                    priceInfo: nil
                )),
                hasMonochromeIcon: true
            )
        )
    }
    .padding()
    .background(Color.Tangem.Surface.level1)
    .preferredColorScheme(.dark)
}

#endif // DEBUG
