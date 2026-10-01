//
//  TangemDropDownShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct TangemDropDownShowcase: View {
    @State private var selectedCategory: Category = .all
    @State private var sortByBalance = false
    @State private var groupByNetwork = false

    var body: some View {
        DSShowcase("TangemDropDown") { controls in
            controls.readout("Category", selectedCategory.text)
            controls.toggle("Group by network", $groupByNetwork)
            controls.toggle("Sort by balance", $sortByBalance)
            controls.note("\"Sort by balance\" in the menu is disabled while sorting is on.")
        } stage: {
            VStack(alignment: .leading, spacing: 8) {
                TangemDropDown(singleSelection: $selectedCategory, in: Category.allCases)

                HStack {
                    Text("Mixed items + custom label")
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

                    Spacer()

                    TangemDropDown(items: menuItems) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .resizable()
                            .frame(width: 28, height: 28)
                    }
                }

                VStack(spacing: 8) {
                    ForEach(visibleAssets) { asset in
                        row(asset)
                    }
                }
            }
        }
    }

    private var menuItems: [TangemDropDownItem] {
        [
            TangemDropDownItem(
                text: "Group by network",
                isChecked: groupByNetwork,
                action: { groupByNetwork.toggle() }
            ),
            TangemDropDownItem(
                text: "Sort by balance",
                isEnabled: !sortByBalance,
                action: { sortByBalance = true }
            ),
        ]
    }

    private var visibleAssets: [Asset] {
        let filtered = Asset.all.filter { selectedCategory == .all || $0.category == selectedCategory }
        return sortByBalance ? filtered.sorted { $0.fiatBalance > $1.fiatBalance } : filtered
    }

    private func row(_ asset: Asset) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(asset.name)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                Text(groupByNetwork ? asset.network : asset.category.text)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)
            }

            Spacer()

            Text(asset.fiatBalance, format: .currency(code: "USD"))
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(DesignSystem.Color.bgPrimary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private extension TangemDropDownShowcase {
    enum Category: TangemDropDownTextProvider, CaseIterable {
        case all
        case coins
        case stablecoins

        var text: String {
            switch self {
            case .all: "All"
            case .coins: "Coins"
            case .stablecoins: "Stablecoins"
            }
        }
    }

    struct Asset: Identifiable {
        let name: String
        let network: String
        let category: Category
        let fiatBalance: Decimal

        var id: String { "\(name)-\(network)" }

        static var all: [Asset] {
            [
                Asset(name: "Bitcoin", network: "Bitcoin", category: .coins, fiatBalance: 12480.35),
                Asset(name: "Ethereum", network: "Ethereum", category: .coins, fiatBalance: 3150.12),
                Asset(name: "Solana", network: "Solana", category: .coins, fiatBalance: 842.07),
                Asset(name: "TRON", network: "TRON", category: .coins, fiatBalance: 96.4),
                Asset(name: "Tether", network: "TRON", category: .stablecoins, fiatBalance: 2500),
                Asset(name: "USD Coin", network: "Ethereum", category: .stablecoins, fiatBalance: 1200.5),
                Asset(name: "Dai", network: "Polygon", category: .stablecoins, fiatBalance: 318.9),
                Asset(name: "PayPal USD", network: "Solana", category: .stablecoins, fiatBalance: 50),
            ]
        }
    }
}
#endif
