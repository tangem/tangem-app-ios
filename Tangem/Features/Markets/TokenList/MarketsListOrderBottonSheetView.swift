//
//  MarketsListOrderBottonSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

struct MarketsListOrderBottomSheetView: View {
    @ObservedObject var viewModel: MarketsListOrderBottomSheetViewModel

    var body: some View {
        VStack(spacing: .zero) {
            BottomSheetHeaderView(title: Localization.marketsSortByTitle)

            GroupedSection(viewModel.listOptionViewModel) {
                DefaultSelectableRowView(data: $0, selection: $viewModel.currentOrderType)
                    .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsSortOption($0.id.rawValue))
            }
            .settings(\.backgroundColor, DesignSystem.Color.bgTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }
}
