//
//  EarnNetworkFilterBottomSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct EarnNetworkFilterBottomSheetView: View {
    @ObservedObject var viewModel: EarnNetworkFilterBottomSheetViewModel

    var body: some View {
        VStack(spacing: .zero) {
            BottomSheetHeaderView(title: viewModel.title)

            GroupedSection(viewModel.presetRowViewModels) { data in
                DefaultSelectableRowView(data: data, selection: viewModel.selectionBinding)
            }
            .settings(\.backgroundColor, Colors.Background.action)

            GroupedSection(viewModel.networkItemViewModels) { itemViewModel in
                AddCustomTokenNetworksListItemView(viewModel: itemViewModel)
            }
            .settings(\.backgroundColor, Colors.Background.action)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }
}
