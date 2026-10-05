//
//  SegmentedControlShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemUI

struct SegmentedControlShowcase: View {
    @State private var segmentCount = 3
    @State private var titles: TitleSet = .periods
    @State private var isLoading = false
    @State private var selection = 0

    var body: some View {
        DSShowcase("Segmented Control", background: .gradient) { controls in
            controls.value("Segments", $segmentCount, in: 2 ... titles.values.count)
            controls.picker("Titles", $titles)
            controls.toggle("Loading", $isLoading)
            controls.readout("Selected", items.first { $0.id == selection }?.title ?? "none")
        } stage: {
            SegmentedControl(items: items, selection: $selection)
                .loading(isLoading)
                .padding(.vertical, 28)
        } matrix: {
            DSShowcaseMatrix(rows: TitleSet.allCases, columns: SegmentState.allCases) { titles, state in
                SegmentedControl(items: Self.items(titles, count: 3), selection: .constant(1))
                    .loading(state == .loading)
                    .frame(width: 300)
            }

            DSShowcaseGroup("Segment count") {
                DSShowcaseMatrix(rows: Array(2 ... TitleSet.periods.values.count)) { count in
                    SegmentedControl(items: Self.items(.periods, count: count), selection: .constant(0))
                        .frame(width: 300)
                }
            }
        }
        .onChange(of: titles) { titles in
            segmentCount = min(segmentCount, titles.values.count)
        }
        .onChange(of: items.count) { count in
            selection = min(selection, count - 1)
        }
    }

    private var items: [SegmentedControl<Int>.Item] {
        Self.items(titles, count: segmentCount)
    }

    private static func items(_ titles: TitleSet, count: Int) -> [SegmentedControl<Int>.Item] {
        titles.values.prefix(count).enumerated().map { index, title in
            SegmentedControl<Int>.Item(id: index, title: title)
        }
    }
}

private extension SegmentedControlShowcase {
    enum TitleSet: CaseIterable {
        case periods
        case pair
        case long

        var values: [String] {
            switch self {
            case .periods: ["1D", "1W", "1M", "1Y", "All"]
            case .pair: ["Tokens", "NFT"]
            case .long: ["Portfolio", "Watchlist", "Trending now", "Recently added", "Everything else"]
            }
        }
    }

    enum SegmentState: CaseIterable {
        case idle
        case loading
    }
}
#endif
