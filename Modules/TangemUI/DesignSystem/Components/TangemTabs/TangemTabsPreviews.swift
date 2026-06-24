//
//  TangemTabsPreviews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Showcase

public struct TangemTabsShowcase: View {
    @State private var colorScheme: ColorScheme = .light
    @State private var dynamicTypeSize: DynamicTypeSize = .large

    struct Item: TangemTabsTextProvider {
        let id = UUID()
        let text: String
    }

    private let items: [Item] = [
        Item(text: "First"),
        Item(text: "Second"),
        Item(text: "Third"),
        Item(text: "Fourth"),
        Item(text: "Fifth"),
    ]

    @State private var selectedItem: Item

    public init() {
        selectedItem = items.first!
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
        ScrollView(.horizontal, showsIndicators: false) {
            TangemTabs(data: items, selection: $selectedItem)
        }
    }
}

// MARK: - Previews

#Preview("Interactive Demo") {
    TangemTabsShowcase()
}
