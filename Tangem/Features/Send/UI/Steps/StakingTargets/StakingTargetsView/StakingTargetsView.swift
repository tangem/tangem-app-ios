//
//  StakingTargetsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct StakingTargetsView: View {
    @ObservedObject var viewModel: StakingTargetsViewModel

    var body: some View {
        GroupedScrollView(contentType: .lazy(alignment: .center, spacing: 20)) {
            GroupedSection(viewModel.targets) { data in
                StakingTargetView(data: data, selection: $viewModel.selectedTarget)
            }
            .settings(\.backgroundColor, Colors.Background.action)
        }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }
}
