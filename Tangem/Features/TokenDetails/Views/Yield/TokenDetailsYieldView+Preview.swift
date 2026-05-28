//
//  TokenDetailsYieldView+Preview.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

// MARK: - Previews

#if DEBUG

private struct TokenDetailsYieldInteractivePreview: View {
    @State private var selectedState: PreviewYieldState = .available
    @State private var colorScheme: ColorScheme = .light
    @State private var dynamicTypeSize: DynamicTypeSize = .large

    var body: some View {
        VStack(spacing: 16) {
            pickerSection

            Spacer()

            TokenDetailsYieldView(state: selectedState.toYieldState())

            Spacer()
        }
        .padding()
        .dynamicTypeSize(dynamicTypeSize)
        .background(Color.Tangem.Surface.level1)
        .environment(\.colorScheme, colorScheme)
    }

    private var pickerSection: some View {
        VStack {
            previewPicker(title: "State", selection: $selectedState)

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

    @ViewBuilder
    private func previewPicker<State: RawRepresentable & CaseIterable & Hashable & Identifiable>(
        title: String,
        selection: Binding<State>
    ) -> some View where State.RawValue == String, State.AllCases: RandomAccessCollection {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("· \(selection.wrappedValue.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Picker(title, selection: selection) {
                ForEach(State.allCases) { state in
                    Text(state.rawValue).tag(state)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

private enum PreviewYieldState: String, CaseIterable, Identifiable {
    case loading = "Loading"
    case available = "Available"
    case processingEnabling = "Processing (Enabling)"
    case processingDisabling = "Processing (Disabling)"
    case activeNoBadge = "Active (No Badge)"
    case activeAttention = "Active (Attention)"
    case activeWarning = "Active (Warning)"

    var id: String { rawValue }

    func toYieldState() -> TokenDetailsYieldState {
        switch self {
        case .loading:
            return .loading

        case .available:
            return .available(item: .init(
                title: "Earn 4.8% APY",
                description: "Start earning yield on your USDC",
                action: .init(title: "Enable", closure: {})
            ))

        case .processingEnabling:
            return .processing(item: .init(
                type: .enabling,
                title: "Yield Mode",
                description: "Enabling..."
            ))

        case .processingDisabling:
            return .processing(item: .init(
                type: .disabling,
                title: "Yield Mode",
                description: "Disabling..."
            ))

        case .activeNoBadge:
            return .active(item: .init(
                title: "Yield Mode",
                description: "APY · 4.8%",
                badgeType: { .none },
                action: .init(title: "Details", closure: {})
            ))

        case .activeAttention:
            return .active(item: .init(
                title: "Yield Mode",
                description: "APY · 4.8%",
                badgeType: { .attention },
                action: .init(title: "Details", closure: {})
            ))

        case .activeWarning:
            return .active(item: .init(
                title: "Yield Mode",
                description: "APY · 4.8%",
                badgeType: { .warning },
                action: .init(title: "Details", closure: {})
            ))
        }
    }
}

struct TokenDetailsYieldView_Previews: PreviewProvider {
    static var previews: some View {
        TokenDetailsYieldInteractivePreview()
            .previewDisplayName("Interactive")
    }
}

#endif // DEBUG
