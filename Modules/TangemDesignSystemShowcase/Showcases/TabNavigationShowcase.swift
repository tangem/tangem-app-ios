//
//  TabNavigationShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI

struct TabNavigationShowcase: View {
    @State private var variant: TabNavigationVariant = .material
    @State private var itemCount = 3
    @State private var isScrollable = false
    @State private var isLoading = false
    @State private var start: StartKind? = .icon
    @State private var hasCounters = false
    @State private var isHapticFeedbackEnabled = true
    @State private var selectionID = 0

    var body: some View {
        DSShowcase("Tab Navigation", background: .gradient) { controls in
            controls.picker("Variant", $variant)
            controls.value("Tabs", $itemCount, in: 2 ... Sample.titles.count)
            controls.toggle("Scrollable", $isScrollable)
            controls.toggle("Loading", $isLoading)
            controls.picker("Start", $start)
            controls.toggle("Counters", $hasCounters)
            controls.toggle("Haptic feedback", $isHapticFeedbackEnabled)
            controls.readout("Selected", selectedItem.title)
        } stage: {
            TabNavigation(data: items, selection: selectionBinding)
                .variant(variant)
                .scrollable(isScrollable)
                .loading(isLoading)
                .hapticFeedback(isHapticFeedbackEnabled)
                .padding(.vertical, 28)
        } matrix: {
            DSShowcaseMatrix(rows: TabNavigationVariant.allCases, columns: ContentKind.allCases) { variant, kind in
                let data = Sample.items(count: 3, start: kind.start, hasCounters: kind == .rich)

                TabNavigation(data: data, selection: .constant(data[1]))
                    .variant(variant)
                    .loading(kind == .loading)
                    .frame(width: 320)
            }

            DSShowcaseGroup("Scrollable") {
                let data = Sample.items(count: Sample.titles.count, start: .icon, hasCounters: true)

                DSShowcaseMatrix(rows: TabNavigationVariant.allCases) { variant in
                    TabNavigation(data: data, selection: .constant(data[0]))
                        .variant(variant)
                        .scrollable()
                        .frame(width: 320)
                }
            }
        }
    }

    private var items: [TabNavigationShowcaseItem] {
        Sample.items(count: itemCount, start: start, hasCounters: hasCounters)
    }

    private var selectedItem: TabNavigationShowcaseItem {
        items.first { $0.id == selectionID } ?? items[0]
    }

    private var selectionBinding: Binding<TabNavigationShowcaseItem> {
        Binding(
            get: { selectedItem },
            set: { selectionID = $0.id }
        )
    }
}

private extension TabNavigationShowcase {
    enum StartKind: CaseIterable {
        case icon
        case walletThumbnail
    }

    enum ContentKind: CaseIterable {
        case text
        case rich
        case walletThumbnail
        case loading

        var start: StartKind? {
            switch self {
            case .text, .loading: nil
            case .rich: .icon
            case .walletThumbnail: .walletThumbnail
            }
        }
    }

    enum Sample {
        static var titles: [String] {
            ["Trending", "Sport", "Business", "Politics", "Crypto", "Entertainment"]
        }

        static var walletNames: [String] {
            ["My Wallet", "Savings", "Tangem Ring", "Mobile Wallet", "Long-term Holdings", "Travel"]
        }

        static var icons: [ImageType] {
            [
                DesignSystem.Icons.ChartLineVertical.regular20,
                DesignSystem.Icons.SignUsd.regular20,
                DesignSystem.Icons.Info.regular20,
            ]
        }

        static var walletThumbnails: [ThumbnailWalletViewType] {
            typealias CardCollection = Color.Tangem.CardCollection

            return [
                .card(.init(card: CardCollection.tangem)),
                .twoCards(.init(card: CardCollection.vivid1, secondCard: CardCollection.vivid2)),
                .ring(.init(ring: CardCollection.tangem)),
                .mobileWallet(.init(icon: CardCollection.tangem)),
                .tLetterCard(.init(card: CardCollection.tangem, tLetter: CardCollection.tLogo)),
            ]
        }

        static var counters: [String] {
            ["12", "3", "8", "27", "140", "5"]
        }

        static func items(count: Int, start: StartKind?, hasCounters: Bool) -> [TabNavigationShowcaseItem] {
            (0 ..< count).map { index in
                TabNavigationShowcaseItem(
                    id: index,
                    title: start == .walletThumbnail ? walletNames[index] : titles[index],
                    start: start.map { itemStart(for: $0, at: index) },
                    counter: hasCounters ? counters[index] : nil
                )
            }
        }

        private static func itemStart(for kind: StartKind, at index: Int) -> TabNavigationItemStart {
            switch kind {
            case .icon:
                .icon(icons[index % icons.count])
            case .walletThumbnail:
                .walletThumbnail(walletThumbnails[index % walletThumbnails.count])
            }
        }
    }
}

private struct TabNavigationShowcaseItem: TabNavigationItem {
    let id: Int
    let title: String
    let start: TabNavigationItemStart?
    let counter: String?
}
#endif
