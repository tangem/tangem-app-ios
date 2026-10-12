//
//  FilterGroupShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct FilterGroupShowcase: View {
    @State private var variant: FilterItemVariant = .material
    @State private var pickedIDs: Set<String> = [Self.filters[0].id]
    @State private var isLoading = false
    @State private var backdrop: FilterShowcaseBackdrop = .primary
    @State private var dynamicTypeIndex = Self.dynamicTypeAllCases.firstIndex(of: .large) ?? 0

    private static let filters: [ShowcaseFilter] = [
        ShowcaseFilter(id: "network", label: "Network", value: "Ethereum"),
        ShowcaseFilter(id: "type", label: "Type", value: "Stablecoins"),
        ShowcaseFilter(id: "sort", label: "Sort", value: "Market cap"),
    ]

    private static let dynamicTypeAllCases: [DynamicTypeSize] = Array(DynamicTypeSize.allCases)

    private var dynamicTypeSize: DynamicTypeSize {
        Self.dynamicTypeAllCases[dynamicTypeIndex]
    }

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            group

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    states
                    controls
                }
                .padding(24)
            }
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }

    private var group: some View {
        FilterGroup {
            ForEach(Self.filters) { filter in
                FilterItem(state(for: filter)) {
                    withAnimation(Constants.selection) { _ = pickedIDs.insert(filter.id) }
                }
                .onClear {
                    withAnimation(Constants.selection) { _ = pickedIDs.remove(filter.id) }
                }
                .clearAccessibilityLabel("Clear \(filter.label) filter")
            }
        }
        .variant(variant)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backdrop.view)
        .dynamicTypeSize(dynamicTypeSize)
    }

    private var states: some View {
        section(title: "Every state, both variants") {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(FilterItemVariant.allCases, id: \.self) { variant in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(describing: variant))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)

                        FilterGroup {
                            FilterItem(.inactive(label: "Label")) {}
                            FilterItem(.active(value: "Value")) {}
                                .onClear {}
                            FilterItem(.active(value: "Value", counter: 1)) {}
                                .onClear {}
                            FilterItem(.loading) {}
                        }
                        .variant(variant)
                        .contentPadding(0)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backdrop.view)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .dynamicTypeSize(dynamicTypeSize)
        }
    }

    private var controls: some View {
        section(title: "Controls") {
            Picker("Variant", selection: $variant) {
                ForEach(FilterItemVariant.allCases, id: \.self) { variant in
                    Text(String(describing: variant)).tag(variant)
                }
            }
            .pickerStyle(.segmented)

            Picker("Backdrop", selection: $backdrop) {
                ForEach(FilterShowcaseBackdrop.allCases, id: \.self) { backdrop in
                    Text(backdrop.title).tag(backdrop)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Loading", isOn: $isLoading)
            Stepper("DT: \(String(describing: dynamicTypeSize))", value: $dynamicTypeIndex, in: 0 ... (Self.dynamicTypeAllCases.count - 1))
        }
    }

    private func state(for filter: ShowcaseFilter) -> FilterItemState {
        if isLoading { return .loading }
        guard pickedIDs.contains(filter.id) else { return .inactive(label: filter.label) }
        return .active(value: filter.value)
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let selection: Animation = .timingCurve(0.8, 0, 0.6, 1, duration: 0.3)
}

// MARK: - Filter

private struct ShowcaseFilter: Identifiable {
    let id: String
    let label: String
    let value: String
}

// MARK: - Backdrop

private enum FilterShowcaseBackdrop: CaseIterable, Hashable {
    case primary
    case secondary
    case colorful

    var title: String {
        switch self {
        case .primary: "Primary"
        case .secondary: "Secondary"
        case .colorful: "Colorful"
        }
    }

    @ViewBuilder
    var view: some View {
        switch self {
        case .primary:
            DesignSystem.Color.bgPrimary
        case .secondary:
            DesignSystem.Color.bgSecondary
        case .colorful:
            LinearGradient(
                colors: [.red, .orange, .yellow, .green, .blue, .purple],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}
