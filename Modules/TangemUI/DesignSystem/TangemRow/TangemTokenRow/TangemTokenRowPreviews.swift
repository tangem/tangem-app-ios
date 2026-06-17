//
//  TangemTokenRowPreviews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Showcase

public struct TangemTokenRowShowcase: View {
    private enum ContentMode: String, CaseIterable, Identifiable {
        case loaded
        case loading
        case error
        case compact
        var id: Self { self }
    }

    private enum BadgeMode: String, CaseIterable, Identifiable {
        case none
        case pending
        case rewards
        var id: Self { self }
    }

    private enum IconColor: String, CaseIterable, Identifiable {
        case orange
        case blue
        case purple
        case green
        case red
        case yellow

        var id: Self { self }

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

    @State private var contentMode: ContentMode = .loaded
    @State private var badgeMode: BadgeMode = .none
    @State private var iconColor: IconColor = .orange
    @State private var name: String = "Bitcoin"
    @State private var monochromeIcon = false
    @State private var hasCachedValues = false
    @State private var fiatFailed = false
    @State private var cryptoFailed = false
    @State private var hasPriceInfo = true
    @State private var priceChangeType: PriceChangeView.ChangeType = .positive
    @State private var hasCompactSubtitle = true
    @State private var hasCompactTrailingIcon = false
    @State private var rewardsActive = true
    @State private var rewardsUpdating = false
    @State private var rowDynamicTypeSize: DynamicTypeSize = .large

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                preview

                Divider()

                contentSection

                badgeSection

                appearanceSection

                stateSpecificSection
            }
            .padding()
        }
        .background(Color.Tangem.Surface.level2)
    }

    // MARK: - Preview

    private var preview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview")
                .font(.headline)

            TangemTokenRow(viewData: viewData)
                .dynamicTypeSize(rowDynamicTypeSize)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.Tangem.Surface.level1)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Stepper(
                value: dynamicTypeIndex,
                in: 0 ... (DynamicTypeSize.allCases.count - 1)
            ) {
                Text("Dynamic Type: \(rowDynamicTypeSize.label)")
                    .monospacedDigit()
            }
        }
    }

    private var dynamicTypeIndex: Binding<Int> {
        Binding(
            get: { DynamicTypeSize.allCases.firstIndex(of: rowDynamicTypeSize) ?? 0 },
            set: { rowDynamicTypeSize = DynamicTypeSize.allCases[$0] }
        )
    }

    // MARK: - Sections

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Content")
                .font(.headline)

            Picker("Content", selection: $contentMode) {
                ForEach(ContentMode.allCases) { mode in
                    Text(mode.rawValue.capitalized).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var badgeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Badge")
                .font(.headline)

            Picker("Badge", selection: $badgeMode) {
                ForEach(BadgeMode.allCases) { mode in
                    Text(mode.rawValue.capitalized).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if badgeMode == .rewards {
                Toggle("Rewards Active", isOn: $rewardsActive)
                Toggle("Rewards Updating (shimmer)", isOn: $rewardsUpdating)
            }
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Appearance")
                .font(.headline)

            HStack {
                Text("Name")
                TextField("Token name", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            Picker("Icon Color", selection: $iconColor) {
                ForEach(IconColor.allCases) { color in
                    Text(color.rawValue.capitalized).tag(color)
                }
            }
            .pickerStyle(.menu)

            Toggle("Monochrome Icon", isOn: $monochromeIcon)
        }
    }

    @ViewBuilder
    private var stateSpecificSection: some View {
        switch contentMode {
        case .loaded:
            loadedControls
        case .loading:
            loadingControls
        case .error:
            EmptyView()
        case .compact:
            compactControls
        }
    }

    private var loadedControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Loaded State")
                .font(.headline)

            Toggle("Fiat balance failed", isOn: $fiatFailed)
            Toggle("Crypto balance failed", isOn: $cryptoFailed)
            Toggle("Has Price Info", isOn: $hasPriceInfo)

            if hasPriceInfo {
                Picker("Price Change", selection: $priceChangeType) {
                    Text("Positive").tag(PriceChangeView.ChangeType.positive)
                    Text("Neutral").tag(PriceChangeView.ChangeType.neutral)
                    Text("Negative").tag(PriceChangeView.ChangeType.negative)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var loadingControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Loading State")
                .font(.headline)

            Toggle("Has Cached Values", isOn: $hasCachedValues)
        }
    }

    private var compactControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Compact State")
                .font(.headline)

            Toggle("Show Subtitle", isOn: $hasCompactSubtitle)
            Toggle("Trailing Drag Handle", isOn: $hasCompactTrailingIcon)
        }
    }

    // MARK: - View Data

    private var viewData: TangemTokenRowViewData {
        TangemTokenRowViewData(
            id: "showcase",
            tokenIconInfo: TokenIconInfo(
                name: name,
                blockchainIconAsset: nil,
                imageURL: nil,
                isCustom: false,
                customTokenColor: iconColor.color
            ),
            name: name,
            badge: badge,
            content: content,
            hasMonochromeIcon: monochromeIcon
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
                isActive: rewardsActive,
                isUpdating: rewardsUpdating
            ))
        }
    }

    private var content: TangemTokenRowViewData.ContentState {
        switch contentMode {
        case .loaded:
            .loaded(TangemTokenRowViewData.LoadedContent(
                balances: TangemTokenRowViewData.Balances(
                    fiat: fiatFailed ? .failed(cached: "$45,123.45") : .value("$45,123.45"),
                    crypto: cryptoFailed ? .failed(cached: "1.234 BTC") : .value("1.234 BTC")
                ),
                priceInfo: hasPriceInfo ? TangemTokenRowViewData.PriceInfo(
                    price: "$45,000.00",
                    change: priceChange
                ) : nil
            ))
        case .loading:
            .loading(
                cached: hasCachedValues ? TangemTokenRowViewData.CachedContent(
                    fiatBalance: "$45,123.45",
                    cryptoBalance: "1.234 BTC"
                ) : nil,
                priceInfo: hasPriceInfo ? TangemTokenRowViewData.PriceInfo(
                    price: "$45,000.00",
                    change: priceChange
                ) : nil
            )
        case .error:
            .error(message: "Network error")
        case .compact:
            .compact(
                subtitle: hasCompactSubtitle ? .loaded(text: "$45,000.00") : .empty,
                trailingIcon: hasCompactTrailingIcon ? Assets.OrganizeTokens.itemDragAndDropIcon : nil
            )
        }
    }

    private var priceChange: TangemTokenRowViewData.PriceChange {
        switch priceChangeType {
        case .positive: .positive("2.34%")
        case .neutral: .neutral("0.00%")
        case .negative: .negative("-1.23%")
        }
    }
}

private extension DynamicTypeSize {
    var label: String {
        switch self {
        case .xSmall: "xS"
        case .small: "S"
        case .medium: "M"
        case .large: "L"
        case .xLarge: "xL"
        case .xxLarge: "xxL"
        case .xxxLarge: "xxxL"
        case .accessibility1: "A1"
        case .accessibility2: "A2"
        case .accessibility3: "A3"
        case .accessibility4: "A4"
        case .accessibility5: "A5"
        @unknown default: "?"
        }
    }
}

#if DEBUG

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
                    content: .loading(
                        cached: TangemTokenRowViewData.CachedContent(
                            fiatBalance: "$3,200.00",
                            cryptoBalance: "1.5 ETH"
                        ),
                        priceInfo: TangemTokenRowViewData.PriceInfo(
                            price: "$2,133.33",
                            change: .positive("2.34%")
                        )
                    ),
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
                    content: .loading(cached: nil, priceInfo: nil),
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
                    content: .compact(subtitle: .loaded(text: "$0.12"), trailingIcon: nil),
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
                    content: .compact(subtitle: .empty, trailingIcon: Assets.OrganizeTokens.itemDragAndDropIcon),
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
                content: .loading(
                    cached: TangemTokenRowViewData.CachedContent(
                        fiatBalance: "$3,200.00",
                        cryptoBalance: "1.5 ETH"
                    ),
                    priceInfo: TangemTokenRowViewData.PriceInfo(
                        price: "$2,133.33",
                        change: .positive("2.34%")
                    )
                ),
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

#Preview("Interactive Showcase") {
    TangemTokenRowShowcase()
}

#endif // DEBUG
