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
import TangemLocalization

struct AddTokenNetworkPickerView: View {
    let viewModel: NetworkSelectorViewModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                sectionHeader

                LazyVStack(spacing: 0) {
                    ForEach(viewModel.itemViewModels) { itemViewModel in
                        NetworkSelectorItemView(viewModel: itemViewModel, style: .addTokenRedesigned)
                    }
                }
            }
            .defaultRoundedBackground(with: Color.Tangem.Surface.level3, verticalPadding: 0)
            .padding(.horizontal, AddTokenRedesignedConstants.horizontalPadding)
            .padding(.top, AddTokenRedesignedConstants.topPadding)
        }
    }

    private var sectionHeader: some View {
        Text(Localization.commonChooseNetwork)
            .frame(maxWidth: .infinity, alignment: .leading)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
            .padding(.top, AddTokenRedesignedConstants.networkPickerSectionHeaderTopPadding)
            .padding(.bottom, AddTokenRedesignedConstants.networkPickerSectionHeaderBottomPadding)
    }
}
