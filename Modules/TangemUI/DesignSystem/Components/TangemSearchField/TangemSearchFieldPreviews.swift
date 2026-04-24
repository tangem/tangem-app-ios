//
//  TangemSearchFieldPreviews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Showcase

public struct TangemSearchFieldShowcase: View {
    @FocusState private var isFocused: Bool
    @State private var text: String = ""

    @State private var cornerStyle: TangemSearchField.CornerStyle = .capsule
    @State private var hasSearchIcon: Bool = true
    @State private var hasClearButton: Bool = true

    @State private var colorScheme: ColorScheme = .light
    @State private var dynamicTypeSize: DynamicTypeSize = .large

    public init() {}

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
                Text("CornerStyle")

                Picker("CornerStyle", selection: $cornerStyle) {
                    Text("capsule").tag(TangemSearchField.CornerStyle.capsule)
                    Text("rounded").tag(TangemSearchField.CornerStyle.rounded)
                }
                .pickerStyle(.segmented)
            }

            Toggle("Has searchIcon", isOn: $hasSearchIcon)
            Toggle("Has clearButton", isOn: $hasClearButton)

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
            TangemSearchField(
                text: $text,
                focusAction: {
                    isFocused = true
                },
                clearAction: {
                    text = ""
                },
                cancelAction: {
                    text = ""
                    isFocused = false
                }
            )
            .cornerStyle(cornerStyle)
            .placeholder(text: "Search Value")
            .configure(
                hasSearchIcon: hasSearchIcon,
                hasClearButton: hasClearButton
            )
            .focused($isFocused)

            Button("Resign focus") {
                isFocused = false
            }
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Interactive Demo") {
    TangemSearchFieldShowcase()
}

#endif // DEBUG
