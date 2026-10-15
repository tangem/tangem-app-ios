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
        rows
            .frame(maxWidth: .infinity)
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
        .shimmering()
        .environment(\.isShimmerActive, viewModel.isRefreshing)
    }

    private var orderRow: some View {
        TangemUI.Row(title: viewModel.orderTitle, subtitle: viewModel.orderCaption)
            .valueAccessory { money(viewModel.orderValue) }
            .contentLead(.end)
            .subtitleLineLimit(nil)
            .verticalAlignment(.top)
            .showDivider()
    }

    private func breakdownRow(title: String, value: String, showsDivider: Bool) -> some View {
        let row = TangemUI.Row(title: title)
            .valueAccessory { money(value) }

        return showsDivider ? row.showDivider() : row
    }

    private func money(_ text: String) -> some View {
        Text(text)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
            .lineLimit(1)
    }
}

// MARK: - Constants

private extension PolymarketFeeBreakdownSheetView {
    enum Constants {
        static let rowsTopPadding: CGFloat = 16

        static let polymarketFeeTitle = Localization.predictionFeeSheetPolymarketFee
        static let tangemBuilderFeeTitle = Localization.predictionFeeSheetBuilderFee
        static let totalTitle = Localization.predictionFeeSheetTotal
    }
}

// MARK: - Previews

@MainActor
private extension PolymarketFeeBreakdownSheetViewModel {
    static func preview() -> PolymarketFeeBreakdownSheetViewModel {
        let model = PolymarketOrderModel.preview(outcomeIndex: 0)
        model.handleViewAction(.onAppear)
        model.handleViewAction(.selectFraction(.half))

        return PolymarketFeeBreakdownSheetViewModel(model: model)
    }
}

#Preview("Sheet") {
    Color.clear.modal(
        isPresented: .constant(true),
        title: Localization.predictionPlaceFee,
        content: { PolymarketFeeBreakdownSheetView(viewModel: .preview()) }
    )
}

#Preview("Sheet — Dark") {
    Color.clear
        .modal(
            isPresented: .constant(true),
            title: Localization.predictionPlaceFee,
            content: { PolymarketFeeBreakdownSheetView(viewModel: .preview()) }
        )
        .preferredColorScheme(.dark)
}
