//
//  FilterGroupShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemUI

struct FilterGroupShowcase: View {
    @State private var variant: FilterItemVariant = .material
    @State private var pickedIDs: Set<String> = ["network"]
    @State private var isLoading = false
    @State private var lastTapped = "none"

    var body: some View {
        DSShowcase("FilterGroup") { controls in
            controls.picker("Variant", $variant)
            controls.toggle("Loading", $isLoading)
            controls.readout("Last tapped", lastTapped)
            controls.action("Reset selection") {
                withAnimation(Self.selection) { pickedIDs = [] }
            }
        } stage: {
            FilterGroup {
                ForEach(Self.filters) { filter in
                    FilterItem(state(for: filter)) {
                        lastTapped = filter.label
                        withAnimation(Self.selection) { _ = pickedIDs.insert(filter.id) }
                    }
                    .onClear {
                        withAnimation(Self.selection) { _ = pickedIDs.remove(filter.id) }
                    }
                    .clearAccessibilityLabel("Clear \(filter.label) filter")
                }
            }
            .variant(variant)
            .contentPadding(0)
        } matrix: {
            DSShowcaseMatrix(rows: FilterItemVariant.allCases, columns: StateSample.allCases) { variant, sample in
                FilterItem(sample.state) {}
                    .onClear(sample.isClearable ? {} : nil)
                    .variant(variant)
            }
        }
    }

    private func state(for filter: ShowcaseFilter) -> FilterItemState {
        if isLoading { return .loading }
        guard pickedIDs.contains(filter.id) else { return .inactive(label: filter.label) }
        return .active(value: filter.value)
    }

    private static var selection: Animation {
        .timingCurve(0.8, 0, 0.6, 1, duration: 0.3)
    }

    private static var filters: [ShowcaseFilter] {
        [
            ShowcaseFilter(id: "network", label: "Network", value: "Ethereum"),
            ShowcaseFilter(id: "type", label: "Type", value: "Stablecoins"),
            ShowcaseFilter(id: "sort", label: "Sort", value: "Market cap"),
        ]
    }
}

private extension FilterGroupShowcase {
    struct ShowcaseFilter: Identifiable {
        let id: String
        let label: String
        let value: String
    }

    enum StateSample: CaseIterable {
        case inactive
        case active
        case activeWithCounter
        case loading

        var state: FilterItemState {
            switch self {
            case .inactive: .inactive(label: "Network")
            case .active: .active(value: "Ethereum")
            case .activeWithCounter: .active(value: "Ethereum", counter: 2)
            case .loading: .loading
            }
        }

        var isClearable: Bool {
            switch self {
            case .active, .activeWithCounter: true
            case .inactive, .loading: false
            }
        }
    }
}
#endif
