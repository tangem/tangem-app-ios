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
            BottomSheetHeaderView(title: "123123123")

            SelectableGropedSection(
                viewModel.listOptionViewModel,
                selection: $viewModel.currentOrderType,
                content: {
                    DefaultSelectableRowView(viewModel: $0)
                }
            )
            .backgroundColor(Colors.Background.action)
        }
        .padding(.horizontal, 16)
    }
}
