//
//  TangemSegmentedPickerPreviews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Showcase

public struct TangemSegmentedPickerShowcase: View {
    @State private var colorScheme: ColorScheme = .light
    @State private var dynamicTypeSize: DynamicTypeSize = .large

    @State private var style: TangemSegmentedPickerStyle = .fixed
    @State private var showSeparators: Bool = true
    @State private var isDisabled: Bool = false

    struct Item: TangemSegmentedPickerTextProvider {
        let id = UUID()
        let text: String
    }

    private let dataSource: [Item] = [
        Item(text: "First"),
        Item(text: "Second"),
        Item(text: "Third"),
        Item(text: "Fourth"),
        Item(text: "Fifth"),
        Item(text: "Sixth"),
        Item(text: "Seventh"),
        Item(text: "Eighth"),
    ]

    @State private var selectedItem: Item
    @State private var selectedCount: Double = 3

    private var items: [Item] {
        Array(dataSource.prefix(Int(selectedCount)))
    }

    public init() {
        selectedItem = dataSource.first!
    }

    public var body: some View {
        VStack(spacing: 16) {
            pickerSection

            Spacer()

            preview

            Spacer()
        }
        .padding()
        .dynamicTypeSize(dynamicTypeSize)
        .background(Color.Tangem.Surface.level1)
        .environment(\.colorScheme, colorScheme)
    }

    private var pickerSection: some View {
        VStack {
            HStack {
                Text("Style")

                Picker("Style", selection: $style) {
                    Text("fixed").tag(TangemSegmentedPickerStyle.fixed)
                    Text("flexible").tag(TangemSegmentedPickerStyle.flexible)
                }
                .pickerStyle(.segmented)
            }

            Toggle("Show separators", isOn: $showSeparators)
            Toggle("Disabled", isOn: $isDisabled)

            HStack {
                Text("Color scheme")

                Picker("ColorScheme", selection: $colorScheme) {
                    Text("light").tag(ColorScheme.light)
                    Text("dark").tag(ColorScheme.dark)
                }
                .pickerStyle(.segmented)
            }

            HStack {
                Text("Dynamic size")

                Picker("DynamicTypeSize", selection: $dynamicTypeSize) {
                    Text("xSmall").tag(DynamicTypeSize.xSmall)
                    Text("default").tag(DynamicTypeSize.large)
                    Text("xxxLarge").tag(DynamicTypeSize.xxxLarge)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var preview: some View {
        VStack {
            HStack {
                Text("Segment count = \(Int(selectedCount))")

                Slider(value: $selectedCount, in: 0 ... Double(dataSource.count), step: 1)
            }

            TangemSegmentedPicker(data: items, selection: $selectedItem)
                .showSeparators(showSeparators)
                .style(style)
                .disabled(isDisabled)
        }
    }
}

// MARK: - Previews

#Preview("Interactive Demo") {
    TangemSegmentedPickerShowcase()
}
