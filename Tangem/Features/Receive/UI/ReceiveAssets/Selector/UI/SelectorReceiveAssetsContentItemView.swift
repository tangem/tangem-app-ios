//
//  SelectorReceiveAssetsContentItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct SelectorReceiveAssetsContentItemView: View {
    private(set) var viewModel: SelectorReceiveAssetsContentItemViewModel

    var body: some View {
        switch viewModel.stateView {
        case .address(let viewModels):
            ForEach(viewModels, id: \.id) { viewModel in
                SelectorReceiveAssetsAddressPageItemView(viewModel: viewModel)
            }
        case .domain(let viewModel):
            SelectorReceiveAssetsDomainItemView(viewModel: viewModel)
        }
    }
}
