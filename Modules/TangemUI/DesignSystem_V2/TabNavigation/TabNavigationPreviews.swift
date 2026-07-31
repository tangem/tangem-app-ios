//
//  TabNavigationPreviews.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Demo item

struct TabNavigationShowcaseItem: TabNavigationItem {
    let id: Int
    let title: String
    var icon: ImageType?
    var counter: String?
}

// MARK: - Showcase

public struct TabNavigationShowcase: View {
    @State private var variant: TabNavigationVariant = .material
    @State private var isScrollable = false
    @State private var isLoading = false
    @State private var showIcons = true
    @State private var showCounters = false
    @State private var selectionID = 0
    @State private var dynamicTypeIndex: Int = Self.dynamicTypeAllCases.firstIndex(of: .large) ?? 0

    private static let dynamicTypeAllCases: [DynamicTypeSize] = Array(DynamicTypeSize.allCases)

    private var dynamicTypeSize: DynamicTypeSize {
        Self.dynamicTypeAllCases[dynamicTypeIndex]
    }

    public init() {}

    public var body: some View {
        VStack(spacing: 24) {
            previewStage

            Spacer()

            pickerSection
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary)
    }

    private var previewStage: some View {
        preview
            .padding(.vertical, 44)
            .frame(maxWidth: .infinity)
            .background { TabNavigationMaterialBackdrop() }
            .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var preview: some View {
        TabNavigation(data: items, selection: selectionBinding)
            .variant(variant)
            .scrollable(isScrollable)
            .loading(isLoading)
            .dynamicTypeSize(dynamicTypeSize)
    }

    private var pickerSection: some View {
        VStack(spacing: 8) {
            Picker("Variant", selection: $variant) {
                Text("material").tag(TabNavigationVariant.material)
                Text("transparent").tag(TabNavigationVariant.transparent)
            }
            .pickerStyle(.segmented)

            Toggle("Scrollable", isOn: $isScrollable)
            Toggle("Loading", isOn: $isLoading)
            Toggle("Icons", isOn: $showIcons)
            Toggle("Counters", isOn: $showCounters)

            Stepper(
                "DT: \(String(describing: dynamicTypeSize))",
                value: $dynamicTypeIndex,
                in: 0 ... (Self.dynamicTypeAllCases.count - 1)
            )
        }
    }

    private var items: [TabNavigationShowcaseItem] {
        [
            TabNavigationShowcaseItem(id: 0, title: "Trending", icon: icon(DesignSystem.Icons.ChartLineVertical.regular20), counter: counter("12")),
            TabNavigationShowcaseItem(id: 1, title: "Sport", icon: icon(DesignSystem.Icons.SignUsd.regular20), counter: counter("3")),
            TabNavigationShowcaseItem(id: 2, title: "Business", icon: icon(DesignSystem.Icons.Info.regular20), counter: counter("8")),
        ]
    }

    private var selectionBinding: Binding<TabNavigationShowcaseItem> {
        Binding(
            get: { items.first { $0.id == selectionID } ?? items[0] },
            set: { selectionID = $0.id }
        )
    }

    private func icon(_ image: ImageType) -> ImageType? {
        showIcons ? image : nil
    }

    private func counter(_ value: String) -> String? {
        showCounters ? value : nil
    }
}

// MARK: - Material backdrop

private struct TabNavigationMaterialBackdrop: View {
    @State private var animate = false

    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.36, green: 0.50, blue: 0.90),
                Color(red: 0.68, green: 0.42, blue: 0.82),
                Color(red: 0.95, green: 0.62, blue: 0.42),
            ],
            startPoint: animate ? .topLeading : .bottomLeading,
            endPoint: animate ? .bottomTrailing : .topTrailing
        )
        .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: animate)
        .onAppear { animate = true }
    }
}

// MARK: - Previews

#if DEBUG

private struct TabNavigationStatesView: View {
    @State private var materialSelection = Self.textItems[1]
    @State private var transparentSelection = Self.textItems[0]
    @State private var richSelection = Self.richItems[1]

    private static let textItems: [TabNavigationShowcaseItem] = [
        .init(id: 0, title: "Trending"),
        .init(id: 1, title: "Sport"),
        .init(id: 2, title: "Business"),
    ]

    private static let richItems: [TabNavigationShowcaseItem] = [
        .init(id: 0, title: "Trending", icon: DesignSystem.Icons.ChartLineVertical.regular20, counter: "12"),
        .init(id: 1, title: "Sport", icon: DesignSystem.Icons.SignUsd.regular20),
        .init(id: 2, title: "Business", icon: DesignSystem.Icons.Info.regular20, counter: "8"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            section("Material") {
                TabNavigation(data: Self.textItems, selection: $materialSelection)
                    .variant(.material)
            }

            section("Transparent") {
                TabNavigation(data: Self.textItems, selection: $transparentSelection)
                    .variant(.transparent)
            }

            section("Icons + counters") {
                TabNavigation(data: Self.richItems, selection: $richSelection)
                    .variant(.material)
            }

            section("Loading") {
                TabNavigation(data: Self.textItems, selection: .constant(Self.textItems[0]))
                    .loading(true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(DesignSystem.Color.bgTertiary)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            content()
        }
    }
}

#Preview("Interactive Demo") {
    TabNavigationShowcase()
}

#Preview("States") {
    TabNavigationStatesView()
}

#Preview("Dark Mode") {
    TabNavigationStatesView()
        .preferredColorScheme(.dark)
}

#Preview("Dynamic Type — XXXLarge") {
    TabNavigationStatesView()
        .dynamicTypeSize(.xxxLarge)
}

#Preview("RTL") {
    TabNavigationStatesView()
        .environment(\.layoutDirection, .rightToLeft)
}

#endif // DEBUG
