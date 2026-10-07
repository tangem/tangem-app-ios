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
    @State private var hasIcons = true
    @State private var hasCounters = false
    @State private var isHapticFeedbackEnabled = true
    @State private var selectionID = 0

    var body: some View {
        DSShowcase("Tab Navigation", background: .gradient) { controls in
            controls.picker("Variant", $variant)
            controls.value("Tabs", $itemCount, in: 2 ... Sample.titles.count)
            controls.toggle("Scrollable", $isScrollable)
            controls.toggle("Loading", $isLoading)
            controls.toggle("Icons", $hasIcons)
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
                let data = Sample.items(count: 3, hasIcons: kind == .rich, hasCounters: kind == .rich)

                TabNavigation(data: data, selection: .constant(data[1]))
                    .variant(variant)
                    .loading(kind == .loading)
                    .frame(width: 320)
            }

            DSShowcaseGroup("Scrollable") {
                let data = Sample.items(count: Sample.titles.count, hasIcons: true, hasCounters: true)

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
        Sample.items(count: itemCount, hasIcons: hasIcons, hasCounters: hasCounters)
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
    enum ContentKind: CaseIterable {
        case text
        case rich
        case loading
    }

    enum Sample {
        static var titles: [String] {
            ["Trending", "Sport", "Business", "Politics", "Crypto", "Entertainment"]
        }

        static var icons: [ImageType] {
            [
                DesignSystem.Icons.ChartLineVertical.regular20,
                DesignSystem.Icons.SignUsd.regular20,
                DesignSystem.Icons.Info.regular20,
            ]
        }

        static var counters: [String] {
            ["12", "3", "8", "27", "140", "5"]
        }

        static func items(count: Int, hasIcons: Bool, hasCounters: Bool) -> [TabNavigationShowcaseItem] {
            (0 ..< count).map { index in
                TabNavigationShowcaseItem(
                    id: index,
                    title: titles[index],
                    icon: hasIcons ? icons[index % icons.count] : nil,
                    counter: hasCounters ? counters[index] : nil
                )
            }
        }
    }
}

private struct TabNavigationShowcaseItem: TabNavigationItem {
    let id: Int
    let title: String
    let icon: ImageType?
    let counter: String?
}
#endif
