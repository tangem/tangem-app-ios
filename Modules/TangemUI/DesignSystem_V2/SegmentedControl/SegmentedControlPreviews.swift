//
//  SegmentedControlPreviews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Showcase

public struct SegmentedControlShowcase: View {
    @State private var segmentCount = 3
    @State private var useLongTitles = false
    @State private var isLoading = false
    @State private var overBusyBackdrop = false
    @State private var selection = 0
    @State private var dynamicTypeIndex: Int = Self.dynamicTypeAllCases.firstIndex(of: .large) ?? 0

    private static let dynamicTypeAllCases: [DynamicTypeSize] = Array(DynamicTypeSize.allCases)
    private static let shortTitles = ["1D", "1W", "1M", "1Y", "All"]
    private static let longTitles = ["Portfolio", "Watchlist", "Trending now", "Recently added", "Everything else"]

    private var dynamicTypeSize: DynamicTypeSize {
        Self.dynamicTypeAllCases[dynamicTypeIndex]
    }

    public init() {}

    public var body: some View {
        VStack(spacing: 24) {
            previewStage

            Spacer()

            controls
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary)
    }

    private var previewStage: some View {
        preview
            .padding(.horizontal, 16)
            .padding(.vertical, 44)
            .frame(maxWidth: .infinity)
            .background { backdrop }
            .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var preview: some View {
        SegmentedControl(items: items, selection: $selection)
            .loading(isLoading)
            .dynamicTypeSize(dynamicTypeSize)
    }

    @ViewBuilder
    private var backdrop: some View {
        if overBusyBackdrop {
            SegmentedControlBusyBackdrop()
        } else {
            DesignSystem.Color.bgSecondary
        }
    }

    private var controls: some View {
        VStack(spacing: 8) {
            Stepper("Segments: \(segmentCount)", value: $segmentCount, in: 2 ... Self.shortTitles.count)

            Toggle("Long titles", isOn: $useLongTitles)
            Toggle("Loading", isOn: $isLoading)
            Toggle("Busy backdrop", isOn: $overBusyBackdrop)

            Stepper(
                "DT: \(String(describing: dynamicTypeSize))",
                value: $dynamicTypeIndex,
                in: 0 ... (Self.dynamicTypeAllCases.count - 1)
            )
        }
    }

    private var items: [SegmentedControl<Int>.Item] {
        let titles = useLongTitles ? Self.longTitles : Self.shortTitles

        return (0 ..< segmentCount).map { index in
            SegmentedControl<Int>.Item(id: index, title: titles[index])
        }
    }
}

// MARK: - Busy backdrop

private struct SegmentedControlBusyBackdrop: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.36, green: 0.50, blue: 0.90),
                Color(red: 0.68, green: 0.42, blue: 0.82),
                Color(red: 0.95, green: 0.62, blue: 0.42),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Previews

#if DEBUG

private struct SegmentedControlStatesView: View {
    @State private var periodSelection = 1
    @State private var pairSelection = 0
    @State private var longSelection = 2

    private static let periodItems: [SegmentedControl<Int>.Item] = [
        SegmentedControl<Int>.Item(id: 0, title: "1D"),
        SegmentedControl<Int>.Item(id: 1, title: "1W"),
        SegmentedControl<Int>.Item(id: 2, title: "1M"),
        SegmentedControl<Int>.Item(id: 3, title: "1Y"),
    ]

    private static let pairItems: [SegmentedControl<Int>.Item] = [
        SegmentedControl<Int>.Item(id: 0, title: "Tokens"),
        SegmentedControl<Int>.Item(id: 1, title: "NFT"),
    ]

    private static let longItems: [SegmentedControl<Int>.Item] = [
        SegmentedControl<Int>.Item(id: 0, title: "Portfolio"),
        SegmentedControl<Int>.Item(id: 1, title: "Watchlist"),
        SegmentedControl<Int>.Item(id: 2, title: "Recently added"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            section("Periods") {
                SegmentedControl(items: Self.periodItems, selection: $periodSelection)
            }

            section("Two segments") {
                SegmentedControl(items: Self.pairItems, selection: $pairSelection)
            }

            section("Truncating titles") {
                SegmentedControl(items: Self.longItems, selection: $longSelection)
            }

            section("Loading") {
                SegmentedControl(items: Self.periodItems, selection: .constant(0))
                    .loading(true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(DesignSystem.Color.bgPrimary)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            content()
        }
    }
}

#Preview("Interactive Demo") {
    SegmentedControlShowcase()
}

#Preview("States") {
    SegmentedControlStatesView()
}

#Preview("Dark Mode") {
    SegmentedControlStatesView()
        .preferredColorScheme(.dark)
}

#Preview("Dynamic Type — XXXLarge") {
    SegmentedControlStatesView()
        .dynamicTypeSize(.xxxLarge)
}

#Preview("RTL") {
    SegmentedControlStatesView()
        .environment(\.layoutDirection, .rightToLeft)
}

#endif // DEBUG
