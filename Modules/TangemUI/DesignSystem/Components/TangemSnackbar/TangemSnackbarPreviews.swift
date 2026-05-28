//
//  TangemSnackbarPreviews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Showcase

public struct TangemSnackbarShowcase: View {
    @State private var colorScheme: ColorScheme = .light
    @State private var dynamicTypeSize: DynamicTypeSize = .medium
    @State private var showIcon = true
    @State private var showAction = true
    @State private var textLength: TextLength = .short

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
        VStack(spacing: 8) {
            Toggle("Show Icon", isOn: $showIcon)
            Toggle("Show Action", isOn: $showAction)

            Picker("Text length", selection: $textLength) {
                Text("short").tag(TextLength.short)
                Text("medium").tag(TextLength.medium)
                Text("long").tag(TextLength.long)
            }
            .pickerStyle(.segmented)

            Picker("ColorScheme", selection: $colorScheme) {
                Text("light").tag(ColorScheme.light)
                Text("dark").tag(ColorScheme.dark)
            }
            .pickerStyle(.segmented)

            Stepper(
                value: dynamicTypeIndex,
                in: 0 ... (DynamicTypeSize.allCases.count - 1)
            ) {
                Text("Dynamic Type: \(String(describing: dynamicTypeSize))")
                    .monospacedDigit()
            }
        }
    }

    private var dynamicTypeIndex: Binding<Int> {
        Binding(
            get: { DynamicTypeSize.allCases.firstIndex(of: dynamicTypeSize) ?? 0 },
            set: { dynamicTypeSize = DynamicTypeSize.allCases[$0] }
        )
    }

    private var preview: some View {
        TangemSnackbar(
            title: textLength.value,
            action: showAction ? TangemSnackbar.Action(title: "Undo", handler: {}) : nil
        )
        .icon(showIcon ? Assets.crossedEyeIcon : nil)
    }
}

private extension TangemSnackbarShowcase {
    enum TextLength: Hashable {
        case short
        case medium
        case long

        var value: String {
            switch self {
            case .short: "Balances hidden"
            case .medium: "Balances hidden across all wallets"
            case .long: "Balances are now hidden across all wallets in your Tangem account"
            }
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Interactive Demo") {
    TangemSnackbarShowcase()
}

#Preview("All States — Light") {
    allStates
        .environment(\.colorScheme, .light)
}

#Preview("All States — Dark") {
    allStates
        .environment(\.colorScheme, .dark)
}

private var allStates: some View {
    ScrollView {
        VStack(spacing: 12) {
            Group {
                TangemSnackbar(
                    title: "Icon + action (Right)",
                    action: TangemSnackbar.Action(title: "Undo", handler: {})
                )
                .icon(Assets.crossedEyeIcon)

                TangemSnackbar(
                    title: "No icon, action (Right)",
                    action: TangemSnackbar.Action(title: "Undo", handler: {})
                )

                TangemSnackbar(title: "Icon, no action")
                    .icon(Assets.crossedEyeIcon)

                TangemSnackbar(title: "No icon, no action")

                TangemSnackbar(
                    title: "Long label forces bottom layout in a single line",
                    action: TangemSnackbar.Action(title: "Undo", handler: {})
                )
                .icon(Assets.crossedEyeIcon)

                TangemSnackbar(
                    title: "Very long body that definitely will not fit on the single Right row and must wrap onto multiple lines using bottom-positioned action layout",
                    action: TangemSnackbar.Action(title: "Undo", handler: {})
                )
                .icon(Assets.crossedEyeIcon)
            }
        }
        .padding()
    }
    .background(Color.Tangem.Surface.level1)
}

#endif // DEBUG
