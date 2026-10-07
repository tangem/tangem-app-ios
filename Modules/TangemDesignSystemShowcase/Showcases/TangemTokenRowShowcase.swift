//
//  TangemTokenRowShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI

struct TangemTokenRowShowcase: View {
    @State private var contentMode: ContentMode = .loaded
    @State private var badgeMode: BadgeMode?
    @State private var iconColor: IconColor = .orange
    @State private var name = "Bitcoin"
    @State private var hasMonochromeIcon = false
    @State private var hasCachedValues = false
    @State private var isFiatFailed = false
    @State private var isCryptoFailed = false
    @State private var hasPriceInfo = true
    @State private var priceChange: PriceChangeKind = .positive
    @State private var hasCompactSubtitle = true
    @State private var hasCompactTrailingIcon = false
    @State private var isRewardsActive = true
    @State private var isRewardsUpdating = false

    var body: some View {
        DSShowcase("TangemTokenRow") { controls in
            controls.picker("Content", $contentMode)
            controls.picker("Badge", $badgeMode)

            if badgeMode == .rewards {
                controls.toggle("Rewards active", $isRewardsActive)
                controls.toggle("Rewards updating", $isRewardsUpdating)
            }

            controls.text("Name", $name)
            controls.picker("Icon color", $iconColor)
            controls.toggle("Monochrome icon", $hasMonochromeIcon)

            switch contentMode {
            case .loaded:
                controls.toggle("Fiat balance failed", $isFiatFailed)
                controls.toggle("Crypto balance failed", $isCryptoFailed)
                priceControls(controls)
            case .loading:
                controls.toggle("Cached values", $hasCachedValues)
                priceControls(controls)
            case .error:
                EmptyView()
            case .compact:
                controls.toggle("Subtitle", $hasCompactSubtitle)
                controls.toggle("Trailing drag handle", $hasCompactTrailingIcon)
            }
        } stage: {
            TangemTokenRow(viewData: viewData)
        } matrix: {
            DSShowcaseMatrix(rows: Example.allCases) { example in
                TangemTokenRow(viewData: example.viewData)
                    .frame(width: 340)
            }
        }
    }

    @ViewBuilder
    private func priceControls(_ controls: DSShowcaseControls) -> some View {
        controls.toggle("Price info", $hasPriceInfo)

        if hasPriceInfo {
            controls.picker("Price change", $priceChange)
        }
    }

    private var viewData: TangemTokenRowViewData {
        Sample.viewData(
            id: "showcase",
            name: name,
            color: iconColor.color,
            badge: badge,
            content: content,
            hasMonochromeIcon: hasMonochromeIcon
        )
    }

    private var badge: TangemTokenRowViewData.Badge? {
        switch badgeMode {
        case .none:
            nil
        case .pending:
            .pendingTransaction
        case .rewards:
            .rewards(TangemTokenRowViewData.RewardsInfo(
                value: "APY 5.2%",
                isActive: isRewardsActive,
                isUpdating: isRewardsUpdating
            ))
        }
    }

    private var priceInfo: TangemTokenRowViewData.PriceInfo? {
        hasPriceInfo ? TangemTokenRowViewData.PriceInfo(price: "$45,000.00", change: priceChange.change) : nil
    }

    private var content: TangemTokenRowViewData.ContentState {
        switch contentMode {
        case .loaded:
            .loaded(TangemTokenRowViewData.LoadedContent(
                balances: TangemTokenRowViewData.Balances(
                    fiat: isFiatFailed ? .failed(cached: "$45,123.45") : .value("$45,123.45"),
                    crypto: isCryptoFailed ? .failed(cached: "1.234 BTC") : .value("1.234 BTC")
                ),
                priceInfo: priceInfo
            ))
        case .loading:
            .loading(
                cached: hasCachedValues ? TangemTokenRowViewData.CachedContent(
                    fiatBalance: "$45,123.45",
                    cryptoBalance: "1.234 BTC"
                ) : nil,
                priceInfo: priceInfo
            )
        case .error:
            .error(message: "Network error")
        case .compact:
            .compact(
                subtitle: hasCompactSubtitle ? .loaded(text: "$45,000.00") : .empty,
                currencySymbol: "BTC",
                trailingIcon: hasCompactTrailingIcon ? Assets.OrganizeTokens.itemDragAndDropIcon : nil
            )
        }
    }
}

private extension TangemTokenRowShowcase {
    enum ContentMode: CaseIterable {
        case loaded
        case loading
        case error
        case compact
    }

    enum BadgeMode: CaseIterable {
        case pending
        case rewards
    }

    enum PriceChangeKind: CaseIterable {
        case positive
        case neutral
        case negative

        var change: TangemTokenRowViewData.PriceChange {
            switch self {
            case .positive: .positive("2.34%")
            case .neutral: .neutral("0.00%")
            case .negative: .negative("-1.23%")
            }
        }
    }

    enum IconColor: CaseIterable {
        case orange
        case blue
        case purple
        case green
        case red
        case yellow

        var color: Color {
            switch self {
            case .orange: .orange
            case .blue: .blue
            case .purple: .purple
            case .green: .green
            case .red: .red
            case .yellow: .yellow
            }
        }
    }

    enum Example: CaseIterable {
        case loaded
        case loadingCached
        case loadingEmpty
        case pendingTransaction
        case rewardsLongName
        case failedCached
        case error
        case compactPrice
        case compactCustom

        var viewData: TangemTokenRowViewData {
            switch self {
            case .loaded:
                Sample.viewData(
                    id: self,
                    name: "Bitcoin",
                    color: .orange,
                    content: .loaded(Sample.loaded(fiat: .value("$45,123.45"), crypto: .value("1.234 BTC"), price: "$45,000.00", change: .positive("2.34%")))
                )
            case .loadingCached:
                Sample.viewData(
                    id: self,
                    name: "Ethereum",
                    color: .blue,
                    content: .loading(
                        cached: TangemTokenRowViewData.CachedContent(fiatBalance: "$3,200.00", cryptoBalance: "1.5 ETH"),
                        priceInfo: TangemTokenRowViewData.PriceInfo(price: "$2,133.33", change: .positive("2.34%"))
                    )
                )
            case .loadingEmpty:
                Sample.viewData(id: self, name: "Ethereum", color: .blue, content: .loading(cached: nil, priceInfo: nil))
            case .pendingTransaction:
                Sample.viewData(
                    id: self,
                    name: "Solana",
                    color: .purple,
                    badge: .pendingTransaction,
                    content: .loaded(Sample.loaded(fiat: .value("$1,234.56"), crypto: .value("10.5 SOL"), price: "$117.57", change: .negative("-1.23%")))
                )
            case .rewardsLongName:
                Sample.viewData(
                    id: self,
                    name: "Cardano Staking Rewards Pool Token",
                    color: .green,
                    badge: .rewards(TangemTokenRowViewData.RewardsInfo(value: "APY 5.2%", isActive: true, isUpdating: false)),
                    content: .loaded(Sample.loaded(fiat: .value("$5,674,566,789,565.89"), crypto: .value("1,234 ADA"), price: "$0.46", change: .neutral("0.00%")))
                )
            case .failedCached:
                Sample.viewData(
                    id: self,
                    name: "Polygon",
                    color: .purple,
                    content: .loaded(TangemTokenRowViewData.LoadedContent(
                        balances: TangemTokenRowViewData.Balances(fiat: .failed(cached: "$89.12"), crypto: .failed(cached: "100 POL")),
                        priceInfo: nil
                    )),
                    hasMonochromeIcon: true
                )
            case .error:
                Sample.viewData(id: self, name: "Unknown Token", color: .gray, content: .error(message: "Network error"), hasMonochromeIcon: true)
            case .compactPrice:
                Sample.viewData(
                    id: self,
                    name: "Dogecoin",
                    color: .yellow,
                    content: .compact(subtitle: .loaded(text: "$0.12"), currencySymbol: "DOGE", trailingIcon: nil)
                )
            case .compactCustom:
                Sample.viewData(
                    id: self,
                    name: "Custom Token",
                    color: .red,
                    isCustom: true,
                    content: .compact(subtitle: .empty, currencySymbol: nil, trailingIcon: Assets.OrganizeTokens.itemDragAndDropIcon)
                )
            }
        }
    }

    enum Sample {
        static func viewData(
            id: AnyHashable,
            name: String,
            color: Color,
            isCustom: Bool = false,
            badge: TangemTokenRowViewData.Badge? = nil,
            content: TangemTokenRowViewData.ContentState,
            hasMonochromeIcon: Bool = false
        ) -> TangemTokenRowViewData {
            TangemTokenRowViewData(
                id: id,
                tokenIconInfo: TokenIconInfo(
                    name: name,
                    blockchainIconAsset: nil,
                    imageURL: nil,
                    isCustom: isCustom,
                    customTokenColor: color
                ),
                name: name,
                badge: badge,
                content: content,
                hasMonochromeIcon: hasMonochromeIcon
            )
        }

        static func loaded(
            fiat: TangemTokenRowViewData.BalanceValue,
            crypto: TangemTokenRowViewData.BalanceValue,
            price: String,
            change: TangemTokenRowViewData.PriceChange
        ) -> TangemTokenRowViewData.LoadedContent {
            TangemTokenRowViewData.LoadedContent(
                balances: TangemTokenRowViewData.Balances(fiat: fiat, crypto: crypto),
                priceInfo: TangemTokenRowViewData.PriceInfo(price: price, change: change)
            )
        }
    }
}
#endif
