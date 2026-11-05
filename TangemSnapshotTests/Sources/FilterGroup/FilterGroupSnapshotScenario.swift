//
//  FilterGroupSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemSnapshotTestSupport
import TangemUI

enum FilterGroupSnapshotScenario: String, SnapshotScenario {
    case items
    case group
    case itemsLargeText

    var canvases: [SnapshotCanvas] {
        self == .group ? [.fixed(width: 402, height: 116)] : [.component]
    }

    var dynamicTypeSize: DynamicTypeSize {
        self == .itemsLargeText ? .accessibility2 : .large
    }

    @MainActor
    @ViewBuilder
    var body: some View {
        switch self {
        case .items, .itemsLargeText:
            SnapshotGrid(itemCases, columns: ItemSample.allCases.count) { sample in
                item(sample.sample).variant(sample.variant)
            }
            .environment(\._accessibilityReduceMotion, true)
        case .group:
            VStack(alignment: .leading, spacing: 16) {
                ForEach(FilterItem.Variant.allCases, id: \.self) { variant in
                    FilterGroup {
                        ForEach(ItemSample.allCases, id: \.self) { sample in
                            item(sample)
                        }
                    }
                    .variant(variant)
                }
            }
            .padding(.vertical, 12)
            .environment(\._accessibilityReduceMotion, true)
        }
    }
}

@MainActor
private extension FilterGroupSnapshotScenario {
    enum ItemSample: CaseIterable, Hashable {
        case inactive
        case active
        case activeWithCounter
        case clearable
        case loading
    }

    var itemCases: [(variant: FilterItem.Variant, sample: ItemSample)] {
        FilterItem.Variant.allCases.flatMap { variant in
            ItemSample.allCases.map { (variant, $0) }
        }
    }

    func item(_ sample: ItemSample) -> FilterItem {
        switch sample {
        case .inactive:
            FilterItem(.inactive(label: "Network"), action: {})
        case .active:
            FilterItem(.active(value: "Ethereum"), action: {})
        case .activeWithCounter:
            FilterItem(.active(value: "Ethereum", counter: 2), action: {})
        case .clearable:
            FilterItem(.active(value: "Ethereum"), action: {}).onClear {}
        case .loading:
            FilterItem(.loading, action: {})
        }
    }
}
