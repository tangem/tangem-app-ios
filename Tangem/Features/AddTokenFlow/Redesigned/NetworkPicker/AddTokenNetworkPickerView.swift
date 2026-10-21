//
//  AddTokenNetworkPickerView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct AddTokenNetworkPickerView: View {
    let viewModel: NetworkSelectorViewModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.itemViewModels) { itemViewModel in
                    NetworkSelectorItemView(viewModel: itemViewModel, style: .addTokenRedesigned)
                }
            }
            .defaultRoundedBackground(with: DesignSystem.Color.bgSecondary, verticalPadding: 0)
            .padding(.horizontal, AddTokenRedesignedConstants.horizontalPadding)
            .padding(.top, AddTokenRedesignedConstants.topPadding)
        }
    }
}
