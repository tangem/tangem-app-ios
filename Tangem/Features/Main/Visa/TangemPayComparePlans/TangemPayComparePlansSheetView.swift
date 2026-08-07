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

    var body: some View {
        VStack(spacing: 0) {
            FloatingSheetNavigationBarView(
                title: viewModel.title,
                backgroundColor: DesignSystem.Color.bgPrimary,
                closeButtonAction: viewModel.close
            )

            ScrollView(showsIndicators: false) {
                VStack(spacing: Constants.sectionSpacing) {
                    ForEach(viewModel.sections) { section in
                        sectionView(section)
                    }
                }
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.top, Constants.contentTopPadding)
                .padding(.bottom, Constants.contentBottomPadding)
            }
        }
        .floatingSheetConfiguration { configuration in
            configuration.maxHeightFraction = Constants.maxHeightFraction
            configuration.sheetBackgroundColor = DesignSystem.Color.bgPrimary
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    private func sectionView(_ section: TangemPayComparePlansSheetViewModel.ComparisonSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(section.title)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

            VStack(spacing: 0) {
                ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, row in
                    TangemRow(title: row.planName, value: row.value)
                        .contentLead(.end)
                        .valueLineLimit(nil)
                        .overrideTextColors(.init(title: DesignSystem.Color.textSecondary))
                        .showDivider(index < section.rows.count - 1)
                }
            }
            .background(DesignSystem.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cardCornerRadius, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension TangemPayComparePlansSheetView {
    enum Constants {
        static let maxHeightFraction: CGFloat = 0.9
        static let sectionSpacing: CGFloat = 24
        static let horizontalPadding: CGFloat = 16
        static let contentTopPadding: CGFloat = 12
        static let contentBottomPadding: CGFloat = 32
        static let cardCornerRadius: CGFloat = 24
    }
}
