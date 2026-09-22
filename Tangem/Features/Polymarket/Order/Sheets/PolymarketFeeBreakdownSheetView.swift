//
//  PolymarketFeeBreakdownSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct PolymarketFeeBreakdownSheetView: View {
    @ObservedObject private var viewModel: PolymarketFeeBreakdownSheetViewModel

    init(viewModel: PolymarketFeeBreakdownSheetViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            title

            ScrollView {
                rows
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Color.bgSecondary.ignoresSafeArea())
        .presentationDetents([.height(Constants.compactHeight), .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Title

    private var title: some View {
        Text(Localization.predictionPlaceFee)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            .lineLimit(1)
            .frame(height: Constants.toolbarHeight)
            .padding(.top, Constants.titleTopPadding)
            .padding(.bottom, Constants.toolbarBottomPadding)
    }

    // MARK: - Rows

    private var rows: some View {
        VStack(spacing: 0) {
            orderRow

            breakdownRow(title: Constants.polymarketFeeTitle, value: viewModel.polymarketFee, showsDivider: true)

            breakdownRow(title: Constants.tangemBuilderFeeTitle, value: viewModel.tangemBuilderFee, showsDivider: true)

            breakdownRow(title: Constants.totalTitle, value: viewModel.total, showsDivider: false)
        }
        .padding(.top, Constants.rowsTopPadding)
        .tangemShimmer()
        .environment(\.isShimmerActive, viewModel.isRefreshing)
    }

    private var orderRow: some View {
        TangemUI.Row(
            title: viewModel.orderTitle,
            subtitle: viewModel.orderCaption,
            value: viewModel.orderValue
        )
        .subtitleLineLimit(nil)
        .valueLineLimit(1)
        .verticalAlignment(.top)
        .overrideTextColors(.init(value: DesignSystem.Color.textSecondary))
        .showDivider()
    }

    private func breakdownRow(title: String, value: String, showsDivider: Bool) -> some View {
        let row = TangemUI.Row(title: title, value: value)
            .overrideTextColors(.init(value: DesignSystem.Color.textSecondary))

        return showsDivider ? row.showDivider() : row
    }
}

// MARK: - Constants

private extension PolymarketFeeBreakdownSheetView {
    enum Constants {
        static let toolbarHeight: CGFloat = 44
        static let titleTopPadding: CGFloat = 16
        static let toolbarBottomPadding: CGFloat = 16
        static let rowsTopPadding: CGFloat = 12
        static let compactHeight: CGFloat = 360

        // [REDACTED_TODO_COMMENT]
        static let polymarketFeeTitle = "Polymarket Fee"
        static let tangemBuilderFeeTitle = "Tangem Builder Fee"
        static let totalTitle = "Total"
    }
}

// MARK: - Previews

@MainActor
private extension PolymarketFeeBreakdownSheetViewModel {
    static func preview() -> PolymarketFeeBreakdownSheetViewModel {
        let model = PolymarketOrderModel.preview(outcomeIndex: 0)
        model.handleViewAction(.screenAppeared)
        model.handleViewAction(.fractionSelected(.half))

        return PolymarketFeeBreakdownSheetViewModel(model: model)
    }
}

#Preview("Sheet") {
    Color.clear.sheet(item: .constant(PolymarketFeeBreakdownSheetViewModel.preview())) { viewModel in
        PolymarketFeeBreakdownSheetView(viewModel: viewModel)
    }
}

#Preview("Sheet — Dark") {
    Color.clear
        .sheet(item: .constant(PolymarketFeeBreakdownSheetViewModel.preview())) { viewModel in
            PolymarketFeeBreakdownSheetView(viewModel: viewModel)
        }
        .preferredColorScheme(.dark)
}
