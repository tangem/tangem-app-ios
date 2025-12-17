//
//  MultipleRewardsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils

struct MultipleRewardsView: View {
    @ObservedObject var viewModel: MultipleRewardsViewModel

    var body: some View {
        NavigationStack {
            GroupedScrollView(contentType: .lazy(alignment: .leading, spacing: 14)) {
                GroupedSection(viewModel.targets) { data in
                    StakingTargetView(data: data)
                }
                .interItemSpacing(0)
                .innerContentPadding(0)
                .backgroundColor(Colors.Background.action)
            }
            .navigationTitle(Localization.commonClaimRewards)
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(viewModel: $viewModel.confirmationDialog)
            .alert(item: $viewModel.alert) { $0.alert }
            .background(Colors.Background.tertiary)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(dismiss: viewModel.dismiss)
                }
            }
        }
    }
}
