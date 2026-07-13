//
//  TokenDetailsStakingView+Preview.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

@available(iOS 17.0, *)
#Preview("Interactive") {
    enum PreviewStakingState: String, CaseIterable, Identifiable {
        case loading = "Loading"
        case available = "Available"
        case enableClaimed = "Enable (Claimed)"
        case enableAuto = "Enable (Auto)"
        case enableEmpty = "Enable (Empty)"
        case unavailable = "Unavailable"
        case unavailableInRegion = "Unavailable (Region)"

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
                    description: "Staking is temporarily unavailable for this token. Please try again later.",
                    action: nil
                ))

            case .unavailableInRegion:
                return .unavailable(item: .init(
                    title: "Staking",
                    description: "Staking is unavailable in your region",
                    action: {}
                ))
            }
        }
    }

    @Previewable @State var selectedState = PreviewStakingState.available
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
                    ForEach(PreviewStakingState.allCases) { state in
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

        TokenDetailsStakingView(state: selectedState.toStakingState())

        Spacer()
    }
    .padding()
    .dynamicTypeSize(dynamicTypeSize)
    .background(Color.Tangem.Surface.level1)
    .environment(\.colorScheme, colorScheme)
}
