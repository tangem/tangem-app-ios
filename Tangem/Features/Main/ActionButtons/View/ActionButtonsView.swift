//
//  ActionButtonsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct ActionButtonsView: View {
    @ObservedObject var viewModel: ActionButtonsViewModel

    var body: some View {
        HStack(spacing: 8) {
            ActionButtonView(viewModel: viewModel.buyActionButtonViewModel)

            ActionButtonView(viewModel: viewModel.swapActionButtonViewModel)
                .unreadNotificationBadge(viewModel.shouldShowSwapUnreadNotificationBadge, badgeColor: Colors.Icon.accent)

            ActionButtonView(viewModel: viewModel.sellActionButtonViewModel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
