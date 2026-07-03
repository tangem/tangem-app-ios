//
//  TangemPayComparePlansSheetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TangemPayComparePlansSheetView: View {
    let viewModel: TangemPayComparePlansSheetViewModel

    @State private var contentOffset = CGPoint(x: 0, y: 0)

    var body: some View {
        VStack(spacing: 0) {
            FloatingSheetNavigationBarView(
                title: viewModel.title,
                backgroundColor: DesignSystem.Color.bgSecondary,
                closeButtonAction: viewModel.close
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
                    ForEach(viewModel.plans) { plan in
                        section(for: plan)
                    }
                }
                .padding(.top, Constants.contentTopPadding)
                .padding(.bottom, Constants.contentBottomPadding)
            }

            TangemPayComparePlansTabsView(
                attributes: viewModel.attributes,
                selectedIndex: selectedIndex,
                onSelect: scroll(toColumn:)
            )
        }
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    private func section(for plan: TangemPayComparePlansSheetViewModel.ComparePlan) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(plan.name)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .padding(.horizontal, 32)
                .frame(height: Constants.sectionLabelHeight, alignment: .leading)

            SyncedHorizontalScrollView(
                contentOffset: $contentOffset,
                itemWidth: Constants.tileWidth,
                step: Constants.step
            ) {
                HStack(spacing: Constants.tileSpacing) {
                    ForEach(Array(plan.cells.enumerated()), id: \.offset) { _, cell in
                        TangemPayComparePlanCell(cell: cell)
                    }
                }
            }
            .frame(height: Constants.tileHeight)
        }
    }
}

// MARK: - Scroll helpers

private extension TangemPayComparePlansSheetView {
    var selectedIndex: Int {
        guard !viewModel.attributes.isEmpty else { return 0 }
        let raw = Int(((contentOffset.x + Constants.rowLeadingInset) / Constants.step).rounded())
        return min(max(raw, 0), viewModel.attributes.count - 1)
    }

    func scroll(toColumn index: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            contentOffset = CGPoint(x: CGFloat(index) * Constants.step - Constants.rowLeadingInset, y: 0)
        }
    }
}

private extension TangemPayComparePlansSheetView {
    enum Constants {
        static let tileWidth: CGFloat = 332
        static let tileHeight: CGFloat = 112
        static let tileSpacing: CGFloat = 8
        static let rowLeadingInset: CGFloat = 16
        static let step: CGFloat = tileWidth + tileSpacing

        static let sectionLabelHeight: CGFloat = 42
        static let sectionSpacing: CGFloat = 24
        static let contentTopPadding: CGFloat = 12
        static let contentBottomPadding: CGFloat = 32
    }
}
