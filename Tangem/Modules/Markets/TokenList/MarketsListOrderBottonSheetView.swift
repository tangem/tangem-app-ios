//
//  MarketsListOrderBottonSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsListOrderBottonSheetView: View {
    @ObservedObject var viewModel: MarketsListOrderBottonSheetViewModel

    var body: some View {
        VStack(spacing: .zero) {
            BottomSheetHeaderView(title: Localization.marketsSortByTitle)

            SelectableGropedSection(
                viewModel.listOptionViewModel,
                selection: $viewModel.currentOrderType,
                content: {
                    DefaultSelectableRowView(viewModel: $0)
                }
            )
            .settings(\.backgroundColor, Colors.Background.action)
        }
        .padding(.horizontal, 16)
    }
}
