//
//  MultipleRewardsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MultipleRewardsView: View {
    @ObservedObject var viewModel: MultipleRewardsViewModel

    var body: some View {
        NavigationView {
            GroupedScrollView(alignment: .leading, spacing: 14) {
                GroupedSection(viewModel.validators) { data in
                    ValidatorView(data: data)
                }
                .interItemSpacing(0)
                .innerContentPadding(0)
                .backgroundColor(Colors.Background.action)
            }
            .navigationTitle(Localization.commonClaimRewards)
            .navigationBarTitleDisplayMode(.inline)
            .background(Colors.Background.tertiary)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(Localization.commonClose, action: viewModel.dismiss)
                        .foregroundColor(Colors.Text.primary1)
                }
            }
            .actionSheet(item: $viewModel.actionSheet) { $0.sheet }
        }
    }
}
