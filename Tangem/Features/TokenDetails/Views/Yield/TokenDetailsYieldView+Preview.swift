//
//  TokenDetailsYieldView+Preview.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

@available(iOS 17.0, *)
#Preview("Interactive") {
    enum PreviewYieldState: String, CaseIterable, Identifiable {
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

    @Previewable @State var selectedState = PreviewYieldState.available
    @Previewable @State var colorScheme = ColorScheme.light
    @Previewable @State var dynamicTypeSize = DynamicTypeSize.large

    return VStack(spacing: 16) {
        VStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("State")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("· \(selectedState.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Picker("State", selection: $selectedState) {
                    ForEach(PreviewYieldState.allCases) { state in
                        Text(state.rawValue).tag(state)
                    }
                }
                .pickerStyle(.segmented)
            }

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

        Spacer()

        TokenDetailsYieldView(state: selectedState.toYieldState())

        Spacer()
    }
    .padding()
    .dynamicTypeSize(dynamicTypeSize)
    .background(Color.Tangem.Surface.level1)
    .environment(\.colorScheme, colorScheme)
}
