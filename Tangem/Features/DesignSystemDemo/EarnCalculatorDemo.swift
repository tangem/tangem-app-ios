//
//  EarnCalculatorDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct EarnCalculatorDemoView: View {
    @State private var hasIncentive = true
    @State private var isRightToLeft = false
    @State private var infoTapCount = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                controls

                EarnCalculatorDemoCard(incentiveApy: hasIncentive ? 0.014 : nil) {
                    infoTapCount += 1
                }
                .id(hasIncentive)
                .environment(\.layoutDirection, isRightToLeft ? .rightToLeft : .leftToRight)
            }
            .padding(16)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .navigationTitle("Earn calculator")
    }
}

// MARK: - Subviews

private extension EarnCalculatorDemoView {
    var controls: some View {
        VStack(spacing: 8) {
            Toggle("Incentive", isOn: $hasIncentive)
            Toggle("Right to left", isOn: $isRightToLeft)

            HStack {
                Text("Info taps")
                Spacer()
                Text("\(infoTapCount)")
            }
        }
        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
    }
}

// MARK: - Card

private struct EarnCalculatorDemoCard: View {
    @StateObject private var viewModel: EarnCalculatorViewModel
    private let onIncentiveInfoTap: () -> Void

    init(incentiveApy: Decimal?, onIncentiveInfoTap: @escaping () -> Void) {
        let viewModel = EarnCalculatorViewModel(
            incentiveApy: incentiveApy,
            projector: StubEarnCalculatorProjector(),
            currencyCode: AppSettings.shared.selectedCurrencyCode
        )
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onIncentiveInfoTap = onIncentiveInfoTap
    }

    var body: some View {
        EarnCalculatorView(viewModel: viewModel, onIncentiveInfoTap: onIncentiveInfoTap)
    }
}
