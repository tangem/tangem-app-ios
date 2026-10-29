//
//  EarnCalculatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct EarnCalculatorView: View {
    @ObservedObject var viewModel: EarnCalculatorViewModel
    var onIncentiveInfoTap: (() -> Void)?

    var body: some View {
        VStack(spacing: .zero) {
            EarnCalculatorHeaderView(
                incentiveBadgeText: viewModel.state.incentiveBadgeText,
                totalBalance: viewModel.state.totalBalance,
                earned: viewModel.state.earned,
                horizonTitle: viewModel.state.horizonTitle,
                horizons: viewModel.horizons,
                selectedHorizon: horizonBinding,
                onIncentiveInfoTap: onIncentiveInfoTap
            )
            .padding(.top, Constants.headerTopPadding)
            .padding(.horizontal, Constants.contentPadding)
            .padding(.bottom, Constants.contentPadding)

            EarnCalculatorChart(bars: viewModel.state.bars, selectedBarID: $viewModel.selectedBarID)
                .padding([.horizontal, .top], Constants.contentPadding)
                .padding(.bottom, Constants.chartBottomPadding)

            inputs
                .padding(Constants.contentPadding)
        }
        .background(
            DesignSystem.Color.bgSecondary,
            in: RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous)
        )
    }
}

// MARK: - Subviews

private extension EarnCalculatorView {
    var horizonBinding: Binding<EarnCalculatorHorizon> {
        Binding(
            get: { viewModel.selectedHorizon },
            set: { viewModel.select(horizon: $0) }
        )
    }

    var inputs: some View {
        VStack(spacing: Constants.inputsSpacing) {
            ForEach(indexed: viewModel.state.inputs) { index, input in
                if index > 0 {
                    Rectangle()
                        .fill(DesignSystem.Color.borderSecondary)
                        .frame(height: Constants.dividerHeight)
                }

                EarnCalculatorInputRow(
                    input: input,
                    onDecrease: { viewModel.decrease(input.field) },
                    onIncrease: { viewModel.increase(input.field) }
                )
            }
        }
    }
}

// MARK: - Constants

private extension EarnCalculatorView {
    enum Constants {
        static let cornerRadius: CGFloat = 24
        static let headerTopPadding: CGFloat = 40
        static let contentPadding: CGFloat = 16
        static let chartBottomPadding: CGFloat = 12
        static let inputsSpacing: CGFloat = 12
        static let dividerHeight: CGFloat = 1
    }
}

// MARK: - Previews

#Preview("Default") {
    EarnCalculatorView(viewModel: .preview())
        .padding(16)
        .background(DesignSystem.Color.bgPrimary)
        .preferredColorScheme(.dark)
}

#Preview("Selected bar") {
    EarnCalculatorView(viewModel: .preview(selectedBarID: 17))
        .padding(16)
        .background(DesignSystem.Color.bgPrimary)
        .preferredColorScheme(.dark)
}

#Preview("No incentive, inputs at minimum") {
    EarnCalculatorView(viewModel: .preview(input: .init(initialBalance: 0, monthlyTopUp: 0, horizon: .tenYears), incentiveApy: nil))
        .padding(16)
        .background(DesignSystem.Color.bgPrimary)
}

private extension EarnCalculatorViewModel {
    static func preview(
        input: EarnCalculatorInput = .default,
        incentiveApy: Decimal? = 0.014,
        selectedBarID: Int? = nil
    ) -> EarnCalculatorViewModel {
        let viewModel = EarnCalculatorViewModel(
            input: input,
            incentiveApy: incentiveApy,
            projector: CompoundingEarnCalculatorProjector.preview,
            currencyCode: "USD"
        )
        viewModel.selectedBarID = selectedBarID
        return viewModel
    }
}
