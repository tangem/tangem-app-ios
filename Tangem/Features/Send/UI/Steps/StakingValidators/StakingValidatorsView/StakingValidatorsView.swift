//
//  StakingValidatorsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct StakingValidatorsView: View {
    @ObservedObject var viewModel: StakingValidatorsViewModel

    var body: some View {
        GroupedScrollView(spacing: 20) {
            GroupedSection(viewModel.validators) { data in
                ValidatorView(data: data, selection: $viewModel.selectedValidator)
            }
            .settings(\.backgroundColor, Colors.Background.action)
        }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }
}
