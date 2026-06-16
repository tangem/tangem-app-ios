//
//  TokenDetailsStakingView+Preview.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

// MARK: - Previews

#if DEBUG

private struct TokenDetailsStakingInteractivePreview: View {
    @State private var selectedState: PreviewStakingState = .available
    @State private var colorScheme: ColorScheme = .light
    @State private var dynamicTypeSize: DynamicTypeSize = .large

    var body: some View {
        VStack(spacing: 16) {
            pickerSection

            Spacer()

            TokenDetailsStakingView(state: selectedState.toStakingState())

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

private enum PreviewStakingState: String, CaseIterable, Identifiable {
    case loading = "Loading"
    case available = "Available"
    case enableClaimed = "Enable (Claimed)"
    case enableAuto = "Enable (Auto)"
    case enableEmpty = "Enable (Empty)"
    case unavailable = "Unavailable"

    var id: String { rawValue }

    func toStakingState() -> TokenDetailsStakingState {
        switch self {
        case .loading:
            return .loading

        case .available:
            return .available(item: .init(
                title: "Earn 5.2% APY",
                description: "Start staking ETH",
                actionTitle: "Stake",
                action: {}
            ))

        case .enableClaimed:
            return .enable(item: .init(
                title: "Staking",
                rewardsState: .claimed("0.0012 ETH unclaimed"),
                fiatBalance: AttributedString("$1,234.56"),
                cryptoBalance: "0.5 ETH",
                action: {}
            ))

        case .enableAuto:
            return .enable(item: .init(
                title: "Staking",
                rewardsState: .auto,
                fiatBalance: AttributedString("$2,450.00"),
                cryptoBalance: "1.0 ETH",
                action: {}
            ))

        case .enableEmpty:
            return .enable(item: .init(
                title: "Staking",
                rewardsState: .empty("No rewards yet"),
                fiatBalance: AttributedString("$489.20"),
                cryptoBalance: "0.2 ETH",
                action: {}
            ))

        case .unavailable:
            return .unavailable(item: .init(
                title: "Staking unavailable",
                description: "Staking is temporarily unavailable for this token. Please try again later."
            ))
        }
    }
}

struct TokenDetailsStakingView_Previews: PreviewProvider {
    static var previews: some View {
        TokenDetailsStakingInteractivePreview()
            .previewDisplayName("Interactive")
    }
}

#endif // DEBUG
